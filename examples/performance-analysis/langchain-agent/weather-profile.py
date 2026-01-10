import argparse
import cProfile
import pstats
import time
import tracemalloc
from io import StringIO

from langchain.agents import create_agent


def check_weather(location: str) -> str:
    '''Return the weather forecast for the specified location.'''
    return f"It's always sunny in {location} ☀️"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--cpuprofile', help='write CPU profile to file')
    parser.add_argument('--memprofile', help='write memory profile to file')
    parser.add_argument('-v', '--verbose', action='store_true', help='verbose timing output')
    parser.add_argument('--city', help='city to query (if empty, tests multiple cities)')
    args = parser.parse_args()

    # Start profiling
    profiler = None
    if args.cpuprofile:
        profiler = cProfile.Profile()
        profiler.enable()
    
    if args.memprofile:
        tracemalloc.start()

    start_time = time.time()
    if args.verbose:
        print("[TIMING] Program start")

    # Build agent once
    build_start = time.time()
    graph = create_agent(
        model="ollama:granite4",
        tools=[check_weather],
        system_prompt="You are a helpful assistant. Don't ask follow-up questions.",
    )
    build_duration = time.time() - build_start
    if args.verbose:
        print(f"[TIMING] Agent build took: {build_duration:.3f}s")

    # Test single city or multiple cities
    if args.city:
        cities = [args.city]
    else:
        cities = ["sf", "nyc", "tokyo", "london", "paris", "sydney"]
    total_run_time = 0.0

    if len(cities) > 1:
        print(f"\n=== Testing {len(cities)} cities ===")
    
    for i, city in enumerate(cities, 1):
        run_start = time.time()
        query = f"will it rain in {city}"
        inputs = {"messages": [{"role": "user", "content": query}]}
        
        response = None
        for chunk in graph.stream(inputs, stream_mode="updates"):
            response = chunk
        
        run_duration = time.time() - run_start
        total_run_time += run_duration
        
        if len(cities) > 1:
            print(f"   [{i}] {city}: {response} (took {run_duration:.3f}s)")
        else:
            print(f"   {city}: {response}")

    print(f"\n=== Summary ===")
    print(f"   Total calls: {len(cities)}")
    print(f"   Total time: {total_run_time:.3f}s")
    print(f"   Average per call: {total_run_time/len(cities):.3f}s")

    if args.verbose:
        print(f"[TIMING] Total execution: {time.time() - start_time:.3f}s")

    # Stop and save profiling data
    if profiler:
        profiler.disable()
        profiler.dump_stats(args.cpuprofile)
        print(f"\nCPU profile saved to {args.cpuprofile}")
        
        # Print summary to console
        s = StringIO()
        ps = pstats.Stats(profiler, stream=s).sort_stats('cumulative')
        ps.print_stats(20)  # Top 20 functions
        print("\nTop CPU-consuming functions:")
        print(s.getvalue())

    if args.memprofile:
        snapshot = tracemalloc.take_snapshot()
        with open(args.memprofile, 'w') as f:
            f.write(f"Memory Profile\n")
            f.write(f"=" * 80 + "\n\n")
            top_stats = snapshot.statistics('lineno')
            f.write("Top 20 memory allocations:\n")
            for stat in top_stats[:20]:
                f.write(f"{stat}\n")
        tracemalloc.stop()
        print(f"Memory profile saved to {args.memprofile}")


if __name__ == "__main__":
    main()