from langchain.agents import create_agent

agent = create_agent(
    model="ollama:gemma3",

    system_prompt="You are a helpful research assistant."
)

result = agent.invoke({
    "messages": [
        {"role": "user", "content": "what is the capital of France?"}
    ]
})

print(result)