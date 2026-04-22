# Simple Streaming Example

This example demonstrates the basic streaming functionality of AgenticGoKit v1beta.

## What it does

- Creates a simple chat agent using Ollama (gemma3:1b model)
- Sends a question about streaming
- Displays tokens as they arrive in real-time
- Shows performance statistics (token count, duration, speed)

## How to run

```bash
cd examples/simple-streaming
go run main.go
```

## Requirements

- Ollama running locally on port 11434
- gemma3:1b model available (`ollama pull gemma3:1b`)

## Expected Output

You'll see tokens streaming in real-time followed by statistics like:

```
🚀 Simple Streaming Example
===========================

❓ Question: Explain what streaming means in the context of AI responses

💬 Streaming Answer:
─────────────────
Streaming in AI responses means... [tokens appear in real-time]

✅ Streaming completed!
📊 Statistics:
• Response length: 234 characters
• Tokens received: 45
• Time taken: 2.1s
• Speed: 21.4 tokens/second

🎉 This is how streaming works! Tokens arrive in real-time instead of waiting for the complete response.
```

This demonstrates the core streaming concept where tokens appear immediately as they're generated, rather than waiting for the complete response.