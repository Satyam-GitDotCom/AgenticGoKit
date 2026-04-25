#!/bin/bash

# Generate flame graphs from existing or new CPU profiles

echo "=== Generating Flame Graphs for Two-LLM-Call Evidence ==="

# Get relative paths based on script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_DIR="$SCRIPT_DIR/simple-agent"
OUTPUT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)/docs/blog/images"
BINARY="$PROFILE_DIR/weather-profile"

mkdir -p "$OUTPUT_DIR"

# Build the binary if not already built
if [ ! -f "$BINARY" ]; then
    echo "Building weather-profile binary..."
    cd "$PROFILE_DIR"
    go build -o weather-profile weather-profile.go
fi

# Generate a new CPU profile with the current (fast) implementation
echo "Generating CPU profile..."
cd "$PROFILE_DIR"
timeout 30 ./weather-profile -city sf -cpuprofile=cpu_new.prof > /dev/null 2>&1 || true

# Generate SVG flame graph from the profile
echo "Generating flame graph SVG..."
if [ -f "$PROFILE_DIR/cpu_new.prof" ]; then
    # Create a web-based flame graph view
    go tool pprof -svg "$BINARY" "$PROFILE_DIR/cpu_new.prof" > "$OUTPUT_DIR/flamegraph-cpu.svg" 2>&1
    echo "✓ Generated: $OUTPUT_DIR/flamegraph-cpu.svg"
    
    # Also generate top functions view
    go tool pprof -text "$BINARY" "$PROFILE_DIR/cpu_new.prof" > "$OUTPUT_DIR/pprof-top-functions.txt" 2>&1
    echo "✓ Generated: $OUTPUT_DIR/pprof-top-functions.txt"
    
    # Generate call graph
    go tool pprof -calls "$BINARY" "$PROFILE_DIR/cpu_new.prof" > "$OUTPUT_DIR/pprof-call-graph.txt" 2>&1
    echo "✓ Generated: $OUTPUT_DIR/pprof-call-graph.txt"
else
    echo "⚠ Could not generate new profile"
fi

# Convert the memory profile too
if [ -f "$PROFILE_DIR/mem.prof" ]; then
    go tool pprof -alloc_space -text "$BINARY" "$PROFILE_DIR/mem.prof" > "$OUTPUT_DIR/pprof-memory-allocations.txt" 2>&1
    echo "✓ Generated: $OUTPUT_DIR/pprof-memory-allocations.txt"
fi

echo ""
echo "=== Flame Graph Generation Complete ==="
echo "Output files in: $OUTPUT_DIR"
ls -lh "$OUTPUT_DIR"/*.{svg,txt} 2>/dev/null || echo "No output files generated"
