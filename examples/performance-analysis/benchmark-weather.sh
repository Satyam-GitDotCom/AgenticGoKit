#!/bin/bash

# Benchmark comparison script for langchain-agent (Python) vs simple-agent (Go)

echo "========================================="
echo "  Benchmark Comparison"
echo "========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ========================================
# 1. SIZE COMPARISON (Weather Tool)
# ========================================
echo -e "${BLUE}1. SIZE COMPARISON (Weather Tool)${NC}"
echo "-----------------------------------"

# Go weather-tool size
if [ -f "simple-agent/weather-tool" ]; then
    go_wt_size=$(du -h simple-agent/weather-tool | cut -f1)
    go_wt_size_bytes=$(stat -c%s simple-agent/weather-tool)
    echo -e "Go weather-tool:   ${GREEN}$go_wt_size${NC} ($go_wt_size_bytes bytes)"
else
    echo "Go weather-tool not found. Building..."
    cd simple-agent && go build -o weather-tool weather-tool.go && cd ..
    go_wt_size=$(du -h simple-agent/weather-tool | cut -f1)
    go_wt_size_bytes=$(stat -c%s simple-agent/weather-tool)
    echo -e "Go weather-tool:   ${GREEN}$go_wt_size${NC} ($go_wt_size_bytes bytes)"
fi

# Python weather-tool script size
py_wt_size=$(du -h langchain-agent/weather-tool.py | cut -f1)
py_wt_size_bytes=$(stat -c%s langchain-agent/weather-tool.py)
echo -e "Python weather-tool:${GREEN} $py_wt_size${NC} ($py_wt_size_bytes bytes)"

# Python with dependencies (if venv exists)
if [ -d "langchain-agent/venv" ]; then
    py_total_size=$(du -sh langchain-agent/venv | cut -f1)
    echo -e "Python venv size: ${YELLOW}$py_total_size${NC}"
fi

echo ""

# ========================================
# 2. SPEED COMPARISON (9 runs each) - Weather Tool
# ========================================
echo -e "${BLUE}2. SPEED COMPARISON (9 runs each)${NC}"
echo "-----------------------------------"

# Run Go weather-tool 10 times (first is warmup)
echo "Running Go weather-tool (warming up + 9 timed runs)..."
go_wt_times=()
for i in 1 2 3 4 5 6 7 8 9 10; do
    start=$(date +%s.%N)
    ./simple-agent/weather-tool > /tmp/go_wt_output_$i.txt 2>&1
    end=$(date +%s.%N)
    runtime=$(echo "$end - $start" | bc)
    if [ $i -eq 1 ]; then
        echo "  Warmup: ${runtime}s (skipped)"
    else
        go_wt_times+=($runtime)
        echo "  Run $((i-1)): ${runtime}s"
    fi
done

# Calculate Go weather-tool statistics (excluding warmup)
go_wt_avg=$(echo "scale=3; (${go_wt_times[0]} + ${go_wt_times[1]} + ${go_wt_times[2]} + ${go_wt_times[3]} + ${go_wt_times[4]} + ${go_wt_times[5]} + ${go_wt_times[6]} + ${go_wt_times[7]} + ${go_wt_times[8]}) / 9" | bc)

# Sort times for min/max/median
IFS=$'\n' go_wt_sorted=($(sort -n <<<"${go_wt_times[*]}"))
unset IFS
go_wt_min=${go_wt_sorted[0]}
go_wt_max=${go_wt_sorted[8]}
go_wt_median=${go_wt_sorted[4]}

echo ""
echo "Go stats: min=${go_wt_min}s, max=${go_wt_max}s, median=${go_wt_median}s, avg=${go_wt_avg}s"
echo ""

# Run Python weather-tool 10 times (first is warmup)
echo "Running Python weather-tool (warming up + 9 timed runs)..."
py_wt_times=()
for i in 1 2 3 4 5 6 7 8 9 10; do
    start=$(date +%s.%N)
    cd langchain-agent && python weather-tool.py > /tmp/py_wt_output_$i.txt 2>&1
    cd ..
    end=$(date +%s.%N)
    runtime=$(echo "$end - $start" | bc)
    if [ $i -eq 1 ]; then
        echo "  Warmup: ${runtime}s (skipped)"
    else
        py_wt_times+=($runtime)
        echo "  Run $((i-1)): ${runtime}s"
    fi
done

# Calculate Python weather-tool statistics (excluding warmup)
py_wt_avg=$(echo "scale=3; (${py_wt_times[0]} + ${py_wt_times[1]} + ${py_wt_times[2]} + ${py_wt_times[3]} + ${py_wt_times[4]} + ${py_wt_times[5]} + ${py_wt_times[6]} + ${py_wt_times[7]} + ${py_wt_times[8]}) / 9" | bc)

# Sort times for min/max/median
IFS=$'\n' py_wt_sorted=($(sort -n <<<"${py_wt_times[*]}"))
unset IFS
py_wt_min=${py_wt_sorted[0]}
py_wt_max=${py_wt_sorted[8]}
py_wt_median=${py_wt_sorted[4]}

echo ""
echo "Python stats: min=${py_wt_min}s, max=${py_wt_max}s, median=${py_wt_median}s, avg=${py_wt_avg}s"
echo "-----------------------------------"
echo "COMPARISON SUMMARY"
echo "-----------------------------------"
echo -e "Go:     avg=${GREEN}${go_wt_avg}s${NC}, median=${GREEN}${go_wt_median}s${NC}, min=${GREEN}${go_wt_min}s${NC}, max=${GREEN}${go_wt_max}s${NC}"
echo -e "Python: avg=${GREEN}${py_wt_avg}s${NC}, median=${GREEN}${py_wt_median}s${NC}, min=${GREEN}${py_wt_min}s${NC}, max=${GREEN}${py_wt_max}s${NC}"
echo ""

# Calculate weather-tool speedup
if (( $(echo "$py_wt_avg > $go_wt_avg" | bc -l) )); then
    wt_speedup=$(echo "scale=2; $py_wt_avg / $go_wt_avg" | bc)
    echo -e "${YELLOW}Go weather-tool is ${wt_speedup}x faster${NC}"
else
    wt_speedup=$(echo "scale=2; $go_wt_avg / $py_wt_avg" | bc)
    echo -e "${YELLOW}Python weather-tool is ${wt_speedup}x faster${NC}"
fi

echo ""

# ========================================
# 3. MEMORY COMPARISON - Weather Tool
# ========================================
echo -e "${BLUE}3. MEMORY COMPARISON${NC}"
echo "-----------------------------------"

# Go weather-tool memory usage
echo "Measuring Go weather-tool memory usage..."
/usr/bin/time -v ./simple-agent/weather-tool > /tmp/go_wt_output.txt 2> /tmp/go_wt_mem.txt
go_wt_mem=$(grep "Maximum resident set size" /tmp/go_wt_mem.txt | awk '{print $6}')
go_wt_mem_mb=$(echo "scale=2; $go_wt_mem / 1024" | bc)
echo -e "Go weather-tool peak:     ${GREEN}${go_wt_mem_mb} MB${NC}"

# Python weather-tool memory usage
echo "Measuring Python weather-tool memory usage..."
cd langchain-agent
/usr/bin/time -v python weather-tool.py > /tmp/py_wt_output.txt 2> /tmp/py_wt_mem.txt
cd ..
py_wt_mem=$(grep "Maximum resident set size" /tmp/py_wt_mem.txt | awk '{print $6}')
py_wt_mem_mb=$(echo "scale=2; $py_wt_mem / 1024" | bc)
echo -e "Python weather-tool peak: ${GREEN}${py_wt_mem_mb} MB${NC}"

echo ""
echo "========================================="
echo "  Summary"
echo "========================================="
echo ""

printf "%-22s %-15s %-15s\n" "Metric" "AgenticGoKit" "Langchain"
echo "-------------------------------------------------------"
printf "%-22s %-15s %-15s\n" "Binary/Script Size" "$go_wt_size" "$py_wt_size"
if [ -n "$py_total_size" ]; then
    printf "%-22s %-15s %-15s\n" "Python venv size" "-" "$py_total_size"
fi
printf "%-22s %-15s %-15s\n" "Min Execution Time" "${go_wt_min}s" "${py_wt_min}s"
printf "%-22s %-15s %-15s\n" "Median Execution Time" "${go_wt_median}s" "${py_wt_median}s"
printf "%-22s %-15s %-15s\n" "Avg Execution Time" "${go_wt_avg}s" "${py_wt_avg}s"
printf "%-22s %-15s %-15s\n" "Max Execution Time" "${go_wt_max}s" "${py_wt_max}s"
printf "%-22s %-15s %-15s\n" "Peak Memory" "${go_wt_mem_mb} MB" "${py_wt_mem_mb} MB"
echo ""

# Cleanup
rm -f /tmp/go_wt_output*.txt /tmp/py_wt_output*.txt /tmp/go_wt_mem.txt /tmp/py_wt_mem.txt

echo "Benchmark complete!"
