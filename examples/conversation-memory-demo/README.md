# Conversation Memory Demo

This example demonstrates how to create an interactive chat agent using the v1beta APIs with memory integration. The agent maintains conversation history and uses it to provide personalized, context-aware responses.

## Features Demonstrated

- **Interactive Chat Interface**: Real-time conversation with the agent
- **Memory Integration**: Automatic storage of conversation history
- **Session-Scoped Memory**: Each conversation maintains its own context
- **RAG (Retrieval-Augmented Generation)**: Context retrieval from chat history
- **In-Memory Storage**: Uses the `chromem` plugin for fast, local storage

## ⚠️ Important: Memory Persistence

This example uses the `chromem` provider, which stores data in memory (RAM).

- Memory is session-scoped
- Memory is lost when the program exits
- Restarting the application starts a fresh conversation with no previous memory

To enable persistent memory across runs, use a database-backed provider such as `pgvector`.

## How Memory Works

### Conversation History Storage

The agent automatically stores every message in the conversation:

1. **User Messages**: Stored as personal memory with tags like "user_message", "conversation"
2. **Assistant Responses**: Stored as personal memory with tags like "agent_response", "conversation"
3. **Chat History**: Maintained separately for sequential context

### Memory Retrieval

When processing new messages, the agent:

1. **Builds Context**: Retrieves relevant conversation history using RAG
2. **Personalizes Responses**: Uses stored information to provide context-aware replies
3. **Maintains Continuity**: References previous topics and user preferences

### Storage Details

- **Provider**: `chromem` (in-memory embedded vector database)
- **Session Scope**: Each conversation gets its own session ID
- **RAG Configuration**:
  - Max context tokens: 1000
  - Personal memory weight: 0.8 (prioritizes conversation history)
  - Knowledge weight: 0.2
  - History limit: 20 messages

## Running the Example

### Prerequisites

1. **Ollama**: Install and run Ollama locally
   ```bash
   # Install Ollama from https://ollama.ai
   ollama serve
   ```

2. **Model**: Pull the required model
   ```bash
   ollama pull llama3.1:8b 
   # This example uses a lightweight model for faster local execution.
   # You can replace it with a larger model if your system supports it.
   ```

### Build and Run

```bash
# Navigate to the example directory
cd examples/v1beta/conversation-memory-demo

# Build the example
go build -o conversation-demo main.go

# Run the demo
./conversation-demo
```

### Sample Conversation

```
👤 You: Hi, I'm Alex and I work as a software engineer.

🤖 Assistant (Turn 1):
Hello Alex! Nice to meet you. As a software engineer, I'm sure you have some interesting projects. What kind of development work do you do?

📊 Memory: Used (1 queries)
⏱️  Response time: 2.3s

👤 You: I mainly work with Go and Kubernetes. What's my name?

🤖 Assistant (Turn 2):
Your name is Alex! And you mentioned working with Go and Kubernetes. That's a great combination for building scalable systems.

📊 Memory: Used (2 queries)
⏱️  Response time: 1.8s
```

## Code Structure

### Agent Configuration

```go
agent, err := v1beta.NewBuilder("chat-assistant").
    WithConfig(&v1beta.Config{
        Name: "chat-assistant",
        SystemPrompt: `You are a helpful and friendly chat assistant...`,
        LLM: v1beta.LLMConfig{
            Provider:    "ollama",
            Model:       "llama3.1:8b",
            Temperature: 0.7,
            MaxTokens:   2000,
        },
        Memory: &v1beta.MemoryConfig{
            Provider: "chromem",
            RAG: &v1beta.RAGConfig{
                MaxTokens:       1000,
                PersonalWeight:  0.8,
                KnowledgeWeight: 0.2,
                HistoryLimit:    20,
            },
        },
        Timeout: 300 * time.Second,
    }).
    Build()
```

### Memory Integration

The memory integration happens automatically:

1. **Initialization**: Memory provider is created during agent initialization
2. **Storage**: Each conversation turn is automatically stored
3. **Retrieval**: Context is retrieved before each LLM call
4. **Cleanup**: Memory is cleaned up when agent is destroyed

### Interactive Loop

The example implements a simple chat loop:

```go
for {
    fmt.Print("👤 You: ")
    userInput := strings.TrimSpace(scanner.Text())

    result, err := agent.Run(ctx, userInput)
    // Display response and memory usage info
}
```

## Memory Inspection

After the conversation ends, the example shows that memory has been stored. In a real application, you could inspect the memory contents by accessing the agent's memory provider directly.

## Customization

### Changing the LLM Model

Edit the `LLMConfig` in `main.go`:

```go
LLM: v1beta.LLMConfig{
    Provider:    "ollama",
    Model:       "llama2:7b",  // Different model
    Temperature: 0.7,
    MaxTokens:   150,
},
```

### Adjusting Memory Settings

Modify the `RAGConfig` to change memory behavior:

```go
RAG: &v1beta.RAGConfig{
    MaxTokens:       2000,  // More context
    PersonalWeight:  0.9,   // Even more focus on conversation
    KnowledgeWeight: 0.1,
    HistoryLimit:    50,    // Keep more messages
},
```

### Using Different Memory Providers

Change the provider in `MemoryConfig`:

```go
Memory: &v1beta.MemoryConfig{
    Provider: "pgvector",  // PostgreSQL with pgvector
    Connection: "postgres://user:pass@localhost/db",
    // ... other config
},
```

## Next Steps

- Try the [memory-and-tools](../memory-and-tools/) example for tool integration
- Explore [streaming-demo](../streaming-demo/) for real-time responses
- Check [mcp-integration](../mcp-integration/) for external tool connections