# MCP Tools Blog Demo - v1beta API

This example demonstrates integrating **MCP (Model Context Protocol) servers** with AgenticGoKit agents, showcasing blog-specific tool operations and both explicit server connections and automatic discovery.

## Features

- ✅ **MCP Server Integration**: Connect to MCP servers for tool access
- ✅ **Tool Discovery**: Automatically discover available tools from MCP servers
- ✅ **Direct Tool Execution**: Execute tools programmatically
- ✅ **Agent-Driven Tool Usage**: Let agents use MCP tools via LLM reasoning
- ✅ **Dual Demo Modes**: Explicit server configuration and port-based discovery
- ✅ **Real MCP Tools**: Blog operations via MCP protocol

## Prerequisites

1. **Install Go**: Ensure Go 1.21+ is installed
2. **Install Ollama**: Download from [ollama.com](https://ollama.com)
3. **Pull the Model**:
   ```bash
   ollama pull gemma3:1b
   ```
   *Note: The example uses `gemma3:1b` - you can modify `main.go` to use any available Ollama model*

4. **MCP Servers**: Ensure MCP servers are running for blog operations. The example expects:
   - Explicit server: `blog-http-sse` on `localhost:8812`
   - Discovery mode: Scans ports `8080, 8081, 8090, 8100, 8811, 8812`

## Quick Start

```bash
# Navigate to the example directory
cd examples/mcp-tools-blog-demo

# Run the example
go run main.go
```

## What It Demonstrates

### 1. Explicit MCP Server Connection
- Configures a specific MCP server (`blog-http-sse`)
- Builds an agent with MCP tools
- Discovers and lists available tools
- Executes tools directly and via agent reasoning

### 2. MCP Discovery Mode
- Automatically discovers MCP servers on specified ports
- Creates an agent with discovered tools
- Runs agent queries using discovered blog tools

## Code Highlights

### MCP Server Configuration
```go
server := v1beta.MCPServer{
    Name:    "blog-http-sse",
    Type:    "http_sse",
    Address: "localhost",
    Port:    8812,
    Enabled: true,
}
```

### Agent with MCP Tools
```go
agent, err := v1beta.NewBuilder("mcp-blog-agent").
    WithConfig(config).
    WithTools(
        v1beta.WithMCP(server),
        v1beta.WithToolTimeout(30*time.Second),
    ).
    Build()
```

### Tool Discovery
```go
tools, err := v1beta.DiscoverTools()
// Lists all available tools (internal + MCP)
```

### Direct Tool Execution
```go
res, err := v1beta.ExecuteToolByName(ctx, "echo", map[string]interface{}{
    "message": "hello from direct call",
})
```

## Expected Output

The example runs two demos:

1. **Explicit Server Demo**: Connects to blog MCP server, discovers tools, executes echo tool, and runs agent query
2. **Discovery Demo**: Discovers MCP servers on ports, creates agent, and queries about technology news

## Framework Evolution

This example uses the **v1beta API**, which will become the stable `v1` package in the next major release.

✅ **Use `v1beta` for new MCP and tool integrations.**

## Next Steps

- Explore [MCP Integration Example](../mcp-integration/) for basic MCP setup
- Try [Memory and Tools Example](../memory-and-tools/) for advanced tool usage
- Check [Sequential Workflow Demo](../sequential-workflow-demo/) for multi-agent tool workflows