# Memory Integration Example

This example demonstrates how to use the memory integration features in AgenticGoKit's v1beta package. It shows how to:

## Features Demonstrated

✅ **Memory Persistence** - Store user profile and preferences  
✅ **Context-Aware Responses** - RAG retrieves relevant context from memory  
✅ **Personalization** - Agent responses tailored to stored user information  
✅ **LLM + Memory Integration** - Prompts enriched with memory context

## What This Example Does

1. **Creates a memory provider** using the InMemory implementation
2. **Stores user profile data** (developer type, preferences, languages)
3. **Creates an agent** configured with memory integration
4. **Runs conversations** where the agent references stored context
5. **Shows memory usage** (whether memory was queried, how many queries)

## How Memory Works

```
User Question
     ↓
Query Memory (RAG)
     ↓
Retrieve Relevant Context
     ↓
Enrich LLM Prompt
     ↓
Generate Personalized Response
```

The agent automatically:
- Queries memory when processing user input
- Retrieves semantically relevant stored information
- Enriches the LLM prompt with this context
- Generates personalized responses

## Requirements

- **Ollama** running locally with `gemma3:1b` model
- Go 1.24.1+

## Running the Example

```bash
# Make sure Ollama is running
ollama list  # Check gemma3:1b is available

# Run the example
cd examples/memory-and-tools
go run main.go
```

## Expected Output

You should see:
1. User profile being stored in memory
2. 5 conversations demonstrating memory usage
3. For each conversation:
   - User question
   - What we expect (e.g., "Should reference Go from memory")
   - Assistant's response (personalized based on stored context)
   - Memory usage stats (queries made)
   - Duration

Example:
```
👤 User [1]: What kind of developer am I?
   💡 Expected: Should reference Go and microservices from memory

🤖 Assistant: Based on the information I have, you are a Go developer working on microservices...
   💾 Memory: Used (queries=2)
   ⏱️  Duration: 1.2s
```

## What to Try

1. **Modify stored preferences** - Change the user profile data and see how responses adapt
2. **Add more context** - Store additional information (projects, technologies, etc.)
3. **Ask follow-up questions** - See how the agent maintains context across conversations
4. **Experiment with RAG weights** - Adjust `PersonalWeight` and `KnowledgeWeight` in config

## RAG Configuration

```go
RAG: &v1beta.RAGConfig{
    MaxTokens:       1000, // Maximum tokens for context window
    PersonalWeight:  0.6,  // Higher = more weight on personal context
    KnowledgeWeight: 0.4,  // Higher = more weight on knowledge base
    HistoryLimit:    10,   // Number of conversation turns to include
}
```

## Next Steps

- Check `test/v1beta/memory/` for comprehensive memory integration tests
- See `v1beta/utils.go` for `EnrichWithMemory()` and RAG helper functions
- Explore `v1beta/agent_impl.go` to see how memory is integrated in `Run()`

## Key Takeaway

Memory integration allows your agents to:
- **Remember user preferences** and context
- **Provide personalized responses** based on stored information
- **Maintain conversation history** across sessions
- **Build RAG-powered context** for better LLM responses

This makes agents much more useful and context-aware!
