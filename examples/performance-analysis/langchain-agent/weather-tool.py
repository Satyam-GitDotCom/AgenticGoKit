from langchain.agents import create_agent


def check_weather(location: str) -> str:
    '''Return the weather forecast for the specified location.'''
    return f"It's always sunny in {location}"


graph = create_agent(
    model="ollama:qwen2.5:3b",
    tools=[check_weather],
    system_prompt="You are a helpful assistant, No follow-up questions.",
)
inputs = {"messages": [{"role": "user", "content": "what is the weather in sf"}]}
for chunk in graph.stream(inputs, stream_mode="updates"):
    print(chunk)