import argparse
import time
import sys
from functools import wraps

# Patch requests to measure individual calls
import requests
original_post = requests.post
call_timings = []

def timed_post(*args, **kwargs):
    start = time.time()
    result = original_post(*args, **kwargs)
    elapsed = time.time() - start
    call_timings.append({
        'url': args[0] if args else kwargs.get('url', 'unknown'),
        'duration': elapsed,
        'size': len(result.content) if result else 0
    })
    return result

requests.post = timed_post

from langchain.agents import create_agent

def check_weather(location: str) -> str:
    '''Return the weather forecast for the specified location.'''
    return f"It's always sunny in {location} ☀️"

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--city', help='city to query')
    args = parser.parse_args()

    cities = [args.city] if args.city else ["sf", "nyc", "tokyo"]
    
    print("=== Building Agent ===")
    build_start = time.time()
    graph = create_agent(
        model="ollama:granite4",
        tools=[check_weather],
        system_prompt="You are a helpful assistant. Don't ask follow-up questions.",
    )
    print(f"Build time: {time.time() - build_start:.3f}s\n")

    print("=== Running Queries ===")
    total_time = 0
    
    for i, city in enumerate(cities, 1):
        call_timings.clear()
        
        run_start = time.time()
        query = f"will it rain in {city}"
        inputs = {"messages": [{"role": "user", "content": query}]}
        
        response = None
        for chunk in graph.stream(inputs, stream_mode="updates"):
            response = chunk
        
        run_duration = time.time() - run_start
        total_time += run_duration
        
        print(f"\nCall {i} ({city}):")
        print(f"  Total time: {run_duration:.3f}s")
        print(f"  API calls made: {len(call_timings)}")
        for j, call in enumerate(call_timings, 1):
            print(f"    [{j}] {call['url'].split('/')[-1]}: {call['duration']:.3f}s ({call['size']} bytes)")

    print(f"\n=== Summary ===")
    print(f"Avg per call: {total_time/len(cities):.3f}s")

if __name__ == "__main__":
    main()
