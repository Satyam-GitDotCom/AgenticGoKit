package main

import (
	"context"
	"fmt"
	"log"
	"time"

	v1beta "github.com/agenticgokit/agenticgokit/v1beta"

	// MCP plugins: provide the manager/transport + registry
	_ "github.com/agenticgokit/agenticgokit/plugins/mcp/default"
	_ "github.com/agenticgokit/agenticgokit/plugins/mcp/unified"

	// LLM provider plugin (swap to your provider if needed)
	_ "github.com/agenticgokit/agenticgokit/plugins/llm/ollama"
)

func main() {
	fmt.Println("=== v1beta MCP + Tools Blog Demo ===")

	if err := runExplicitServer(); err != nil {
		log.Printf("explicit server demo: %v\n", err)
	}

	fmt.Println("\n---------------------------------------------\n")

	if err := runDiscovery(); err != nil {
		log.Printf("discovery demo: %v\n", err)
	}
}

func runExplicitServer() error {
	ctx := context.Background()

	server := v1beta.MCPServer{
		Name:    "blog-http-sse",
		Type:    "http_sse",
		Address: "localhost",
		Port:    8812,
		Enabled: true,
	}

	agent, err := v1beta.NewBuilder("mcp-blog-agent").
		WithConfig(&v1beta.Config{
			Name:         "mcp-blog-agent",
			SystemPrompt: "You are a helpful assistant with access to tools. Use them when helpful and return clear answers.",
			Timeout:      60 * time.Second,
			LLM: v1beta.LLMConfig{
				Provider:    "ollama",
				Model:       "gemma3:1b",
				Temperature: 0.7,
				MaxTokens:   200,
			},
		}).
		WithTools(
			v1beta.WithMCP(server),
			v1beta.WithToolTimeout(30*time.Second),
		).
		Build()
	if err != nil {
		return fmt.Errorf("build agent: %w", err)
	}

	fmt.Printf("Connected server: %s (%s:%d)\n", server.Name, server.Address, server.Port)

	// Show discovered tools (internal + MCP)
	tools, err := v1beta.DiscoverTools()
	if err != nil {
		fmt.Printf("Warning: discover tools: %v\n", err)
	} else {
		fmt.Printf("Discovered %d tools:\n", len(tools))
		for _, t := range tools {
			fmt.Printf("  - %s: %s\n", t.Name(), t.Description())
		}
	}

	// Execute an internal tool directly (echo)
	res, err := v1beta.ExecuteToolByName(ctx, "echo", map[string]interface{}{"message": "hello from direct call"})
	if err != nil {
		fmt.Printf("echo tool error: %v\n", err)
	} else {
		fmt.Printf("echo result: success=%v content=%v\n", res.Success, res.Content)
	}

	// Drive via LLM-like TOOL_CALL output
	llmOutput := "I'll echo something first.\nTOOL_CALL{\"name\": \"echo\", \"args\": {\"message\": \"from llm call\"}}"
	toolResults, _ := v1beta.ExecuteToolsFromLLMResponse(ctx, llmOutput)
	for i, tr := range toolResults {
		fmt.Printf("tool call %d -> success=%v content=%v error=%s\n", i+1, tr.Success, tr.Content, tr.Error)
	}

	// Run the agent end-to-end
	ar, err := agent.Run(ctx, "What tools do you have? Use them if useful.")
	if err != nil {
		return fmt.Errorf("run agent: %w", err)
	}
	fmt.Printf("Agent response: %s (duration=%v)\n", ar.Content, ar.Duration)
	return nil
}

func runDiscovery() error {
	ctx := context.Background()

	agent, err := v1beta.NewBuilder("mcp-discovery-agent").
		WithConfig(&v1beta.Config{
			Name:         "mcp-discovery-agent",
			SystemPrompt: "You are a helpful assistant with discovered MCP tools.",
			Timeout:      60 * time.Second,
			LLM: v1beta.LLMConfig{
				Provider:    "ollama",
				Model:       "gemma3:1b",
				Temperature: 0.7,
				MaxTokens:   200,
			},
		}).
		WithTools(
			v1beta.WithMCPDiscovery(8080, 8081, 8090, 8100, 8811, 8812),
			v1beta.WithToolTimeout(30*time.Second),
		).
		Build()
	if err != nil {
		return fmt.Errorf("build agent (discovery): %w", err)
	}

	ar, err := agent.Run(ctx, "what is latest news about technology?")
	if err != nil {
		return fmt.Errorf("run agent (discovery): %w", err)
	}
	fmt.Printf("Agent response (discovery): %s (duration=%v)\n", ar.Content, ar.Duration)
	return nil
}
