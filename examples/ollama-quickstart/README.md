# Ollama QuickStart Agent - v1beta API

This example demonstrates the streamlined **v1beta Builder API** from AgenticGoKit for creating Ollama-powered agents with minimal code.

## Features

- ✅ **Streamlined Builder Pattern**: Easy agent creation using `v1beta.NewBuilder()`
- ✅ **Ollama Integration**: Seamless connection to local LLMs
- ✅ **Clean Code**: Complete agent setup in under 50 lines
- ✅ **Real LLM Responses**: Fully functional with local Ollama instances

## Prerequisites

1.  **Install Ollama**: Download and install from [ollama.com](https://ollama.com).
2.  **Pull the Model**:
    ```bash
    ollama pull gpt-oss:20b-cloud
    ```
    *Note: You can use any available Ollama model; just update the model name in `main.go` accordingly.*

## Quick Start

```bash
# Navigate to the example directory
cd examples/ollama-quickstart

# Run the example
go run main.go
```

## Code Highlights

### v1beta Builder Pattern

The `v1beta` API uses a fluent builder pattern for a more ergonomic and flexible configuration.

```go
// Initialize defaults (optional but recommended)
v1beta.InitializeDefaults()

// Configure the agent
config := &v1beta.Config{
    Name:         "quick-helper",
    SystemPrompt: "You are a helpful assistant that provides short, concise answers.",
    LLM: v1beta.LLMConfig{
        Provider: "ollama",
        Model:    "gpt-oss:20b-cloud",
    },
}

// Create and build the agent
agent, err := v1beta.NewBuilder(config.Name).
    WithConfig(config).
    WithLLM("ollama", "gpt-oss:20b-cloud"). // Override or set the model
    Build()
```

## Framework Evolution

As part of the **v1.0 migration**, the `v1beta` API replaces the deprecated `core` and `core/vnext` packages. 

✅ **Always use `v1beta` (which will become the stable `v1` package) for new development.**

## Next Steps

- Try the [Builder Pattern Example](../ollama-short-answer/)
- Try the [TOML Config Example](../ollama-config-based/)
- Add streaming with `agent.RunStream()`
