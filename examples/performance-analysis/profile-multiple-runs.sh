#!/bin/bash

# Run weather-tool multiple times and profile each run

RUNS=${1:-10}  # Default to 10 runs, or use first argument

echo "========================================="
echo "  Multi-Run Profiler for Weather-Tool"
echo "========================================="
echo "Running $RUNS iterations..."
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Ensure binary is built
if [ ! -f "simple-agent/weather-tool" ]; then
    echo -e "${YELLOW}Building weather-tool...${NC}"
    cd simple-agent && go build -o weather-tool weather-tool.go && cd ..
fi

# Create profiles directory with timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
PROFILE_DIR="profiles/run_${TIMESTAMP}"
mkdir -p "$PROFILE_DIR"

echo -e "${BLUE}Profiles will be saved to: ${PROFILE_DIR}${NC}"
echo ""

# Arrays to store results
declare -a run_times
declare -a run_numbers

slowest_time=0
slowest_run=0
fastest_time=999999
fastest_run=0

# Run the tool multiple times
for i in $(seq 1 $RUNS); do
    echo -e "${BLUE}Run $i/$RUNS${NC}"
    
    # Measure execution time
    start=$(date +%s.%N)
    
    # Run with profiling
    ./simple-agent/weather-tool \
        -cpuprofile="${PROFILE_DIR}/cpu_run${i}.prof" \
        -memprofile="${PROFILE_DIR}/mem_run${i}.prof" \
        -v > "${PROFILE_DIR}/output_run${i}.txt" 2>&1
    
    end=$(date +%s.%N)
    runtime=$(echo "$end - $start" | bc)
    
    # Store results
    run_times[$i]=$runtime
    run_numbers[$i]=$i
    
    # Track slowest and fastest
    if (( $(echo "$runtime > $slowest_time" | bc -l) )); then
        slowest_time=$runtime
        slowest_run=$i
    fi
    
    if (( $(echo "$runtime < $fastest_time" | bc -l) )); then
        fastest_time=$runtime
        fastest_run=$i
    fi
    
    echo "  Time: ${runtime}s"
    
    # Brief pause to let system stabilize
    sleep 0.5
done

echo ""
echo "========================================="
echo "  Summary"
echo "========================================="
echo ""

# Calculate average
total=0
for i in $(seq 1 $RUNS); do
    total=$(echo "$total + ${run_times[$i]}" | bc)
done
average=$(echo "scale=3; $total / $RUNS" | bc)

# Sort times for median
IFS=$'\n' sorted_times=($(sort -n <<<"${run_times[*]}"))
unset IFS
median_idx=$(( ($RUNS + 1) / 2 ))
median=${sorted_times[$median_idx]}

echo "Run Times:"
echo "-----------------------------------"
for i in $(seq 1 $RUNS); do
    time=${run_times[$i]}
    marker=""
    
    if [ $i -eq $slowest_run ]; then
        marker="${RED}← SLOWEST${NC}"
    elif [ $i -eq $fastest_run ]; then
        marker="${GREEN}← FASTEST${NC}"
    fi
    
    printf "  Run %2d: %8ss  %b\n" $i "$time" "$marker"
done

echo ""
echo "Statistics:"
echo "-----------------------------------"
printf "  Min:    ${GREEN}%8ss${NC} (run %d)\n" "$fastest_time" "$fastest_run"
printf "  Max:    ${RED}%8ss${NC} (run %d)\n" "$slowest_time" "$slowest_run"
printf "  Median: ${BLUE}%8ss${NC}\n" "$median"
printf "  Avg:    ${BLUE}%8ss${NC}\n" "$average"
echo ""

variance=$(echo "$slowest_time - $fastest_time" | bc)
printf "  Variance: ${YELLOW}%8ss${NC} (%.1fx difference)\n" "$variance" $(echo "scale=2; $slowest_time / $fastest_time" | bc)

echo ""
echo "========================================="
echo "  Profile Analysis"
echo "========================================="
echo ""

echo -e "${BLUE}Analyzing SLOWEST run (#${slowest_run})...${NC}"
echo "-----------------------------------"
echo ""
echo "CPU Profile (top 10):"
go tool pprof -top -nodecount=10 "${PROFILE_DIR}/cpu_run${slowest_run}.prof" 2>/dev/null | grep -v "^Showing" | head -15
echo ""
echo "Memory Profile (top 10):"
go tool pprof -top -nodecount=10 "${PROFILE_DIR}/mem_run${slowest_run}.prof" 2>/dev/null | grep -v "^Showing" | head -15
echo ""

echo -e "${BLUE}Analyzing FASTEST run (#${fastest_run})...${NC}"
echo "-----------------------------------"
echo ""
echo "CPU Profile (top 10):"
go tool pprof -top -nodecount=10 "${PROFILE_DIR}/cpu_run${fastest_run}.prof" 2>/dev/null | grep -v "^Showing" | head -15
echo ""

echo "========================================="
echo "  Detailed Analysis Commands"
echo "========================================="
echo ""
echo "View SLOWEST run in browser:"
echo -e "  ${GREEN}go tool pprof -http=:8080 ${PROFILE_DIR}/cpu_run${slowest_run}.prof${NC}"
echo ""
echo "View FASTEST run in browser:"
echo -e "  ${GREEN}go tool pprof -http=:8080 ${PROFILE_DIR}/cpu_run${fastest_run}.prof${NC}"
echo ""
echo "Compare slowest vs fastest:"
echo -e "  ${GREEN}diff ${PROFILE_DIR}/output_run${fastest_run}.txt ${PROFILE_DIR}/output_run${slowest_run}.txt${NC}"
echo ""
echo "View all outputs:"
echo -e "  ${GREEN}ls -lh ${PROFILE_DIR}/${NC}"
echo ""

# Save summary to file
SUMMARY_FILE="${PROFILE_DIR}/summary.txt"
{
    echo "Multi-Run Profile Summary"
    echo "========================="
    echo "Date: $(date)"
    echo "Runs: $RUNS"
    echo ""
    echo "Statistics:"
    echo "  Min:     $fastest_time s (run $fastest_run)"
    echo "  Max:     $slowest_time s (run $slowest_run)"
    echo "  Median:  $median s"
    echo "  Average: $average s"
    echo "  Variance: $variance s"
    echo ""
    echo "Run Times:"
    for i in $(seq 1 $RUNS); do
        printf "  Run %2d: %s s\n" $i "${run_times[$i]}"
    done
} > "$SUMMARY_FILE"

echo -e "${GREEN}Summary saved to: ${SUMMARY_FILE}${NC}"
echo ""
