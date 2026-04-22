package main

import (
	"context"
	"fmt"
	"log"
	"time"

	v1beta "github.com/agenticgokit/agenticgokit/v1beta"
)

func main() {
	fmt.Println("🚀 Simple Streaming Example")
	fmt.Println("===========================")
	fmt.Println()

	// Create a simple agent with Ollama
	agent, err := v1beta.NewBuilder("simple-streamer").
		WithConfig(&v1beta.Config{
			Name:         "simple-streamer",
			SystemPrompt: "You are a helpful assistant. Be concise but friendly.",
			Timeout:      30 * time.Second,
			LLM: v1beta.LLMConfig{
				Provider:    "ollama",
				Model:       "gemma3:1b",
				Temperature: 0.7,
				MaxTokens:   200,
				BaseURL:     "http://localhost:11434",
			},
		}).
		Build()
	if err != nil {
		log.Fatalf("Failed to create agent: %v", err)
	}

	// Ask a question
	prompt := "Explain what streaming means in the context of AI responses"
	fmt.Printf("❓ Question: %s\n\n", prompt)
	fmt.Println("💬 Streaming Answer:")
	fmt.Println("─────────────────")

	// Start streaming with timeout
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	stream, err := agent.RunStream(ctx, prompt)
	if err != nil {
		log.Fatalf("Failed to start streaming: %v", err)
	}

	// Print tokens as they arrive
	var fullResponse string
	tokenCount := 0
	startTime := time.Now()

	for chunk := range stream.Chunks() {
		if chunk.Error != nil {
			fmt.Printf("\n❌ Error: %v\n", chunk.Error)
			break
		}

		switch chunk.Type {
		case v1beta.ChunkTypeDelta:
			// Print each token immediately
			fmt.Print(chunk.Delta)
			fullResponse += chunk.Delta
			tokenCount++
		case v1beta.ChunkTypeDone:
			fmt.Println("\n\n✅ Streaming completed!")
		}
	}

	// Show statistics
	duration := time.Since(startTime)
	fmt.Println("📊 Statistics:")
	fmt.Printf("• Response length: %d characters\n", len(fullResponse))
	fmt.Printf("• Tokens received: %d\n", tokenCount)
	fmt.Printf("• Time taken: %v\n", duration)
	fmt.Printf("• Speed: %.1f tokens/second\n", float64(tokenCount)/duration.Seconds())

	fmt.Println("\n🎉 This is how streaming works! Tokens arrive in real-time instead of waiting for the complete response.")
}
