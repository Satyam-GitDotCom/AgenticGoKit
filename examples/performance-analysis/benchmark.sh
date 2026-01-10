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
# 1. SIZE COMPARISON (Agents)
# ========================================
echo -e "${BLUE}1. SIZE COMPARISON (Agents)${NC}"
echo "-----------------------------------"

# Go binary size
if [ -f "simple-agent/simple-agent" ]; then
    go_size=$(du -h simple-agent/simple-agent | cut -f1)
    go_size_bytes=$(stat -c%s simple-agent/simple-agent)
    echo -e "Go binary:        ${GREEN}$go_size${NC} ($go_size_bytes bytes)"
else
    echo "Go binary not found. Building..."
    cd simple-agent && go build -o simple-agent main.go && cd ..
    go_size=$(du -h simple-agent/simple-agent | cut -f1)
    go_size_bytes=$(stat -c%s simple-agent/simple-agent)
    echo -e "Go binary:        ${GREEN}$go_size${NC} ($go_size_bytes bytes)"
fi

# Python script size (just the script, not dependencies)
py_size=$(du -h langchain-agent/main.py | cut -f1)
py_size_bytes=$(stat -c%s langchain-agent/main.py)
echo -e "Python script:    ${GREEN}$py_size${NC} ($py_size_bytes bytes)"

# Python with dependencies (if venv exists)
if [ -d "langchain-agent/venv" ]; then
    py_total_size=$(du -sh langchain-agent/venv | cut -f1)
    echo -e "Python venv size: ${YELLOW}$py_total_size${NC}"
fi

echo ""

# ========================================
# 1b. SIZE COMPARISON (Weather Tool)
# ========================================
echo -e "${BLUE}1b. SIZE COMPARISON (Weather Tool)${NC}"
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
# 2. SPEED COMPARISON (9 runs each) - Agents
# ========================================
echo -e "${BLUE}2. SPEED COMPARISON (9 runs each) - Agents${NC}"
echo "-----------------------------------"

# Run Go agent 3 times
echo "Running Go agent..."
go_times=()
for i in 1 2 3 4 5 6 7 8 9; do
    start=$(date +%s.%N)
    ./simple-agent/simple-agent > /tmp/go_output_$i.txt 2>&1
    end=$(date +%s.%N)
    runtime=$(echo "$end - $start" | bc)
    go_times+=($runtime)
    echo "  Run $i: ${runtime}s"
done

# Calculate Go average
go_avg=$(echo "scale=3; (${go_times[0]} + ${go_times[1]} + ${go_times[2]} + ${go_times[3]} + ${go_times[4]} + ${go_times[5]} + ${go_times[6]} + ${go_times[7]} + ${go_times[8]}) / 9" | bc)

echo ""

# Run Python agent 3 times
echo "Running Python agent..."
py_times=()
for i in 1 2 3 4 5 6 7 8 9; do
    start=$(date +%s.%N)
    cd langchain-agent && python main.py > /tmp/py_output_$i.txt 2>&1
    cd ..
    end=$(date +%s.%N)
    runtime=$(echo "$end - $start" | bc)
    py_times+=($runtime)
    echo "  Run $i: ${runtime}s"
done

# Calculate Python average
py_avg=$(echo "scale=3; (${py_times[0]} + ${py_times[1]} + ${py_times[2]} + ${py_times[3]} + ${py_times[4]} + ${py_times[5]} + ${py_times[6]} + ${py_times[7]} + ${py_times[8]}) / 9" | bc)

echo ""
echo "-----------------------------------"
echo -e "Go average:     ${GREEN}${go_avg}s${NC}"
echo -e "Python average: ${GREEN}${py_avg}s${NC}"

# Calculate speedup
if (( $(echo "$py_avg > $go_avg" | bc -l) )); then
    speedup=$(echo "scale=2; $py_avg / $go_avg" | bc)
    echo -e "${YELLOW}Go is ${speedup}x faster${NC}"
else
    speedup=$(echo "scale=2; $go_avg / $py_avg" | bc)
    echo -e "${YELLOW}Python is ${speedup}x faster${NC}"
fi

echo ""

# ========================================
# 2b. SPEED COMPARISON (9 runs each) - Weather Tool
# ========================================
echo -e "${BLUE}2b. SPEED COMPARISON (9 runs each) - Weather Tool${NC}"
echo "-----------------------------------"

# Run Go weather-tool 9 times
echo "Running Go weather-tool..."
go_wt_times=()
for i in 1 2 3 4 5 6 7 8 9; do
    start=$(date +%s.%N)
    ./simple-agent/weather-tool > /tmp/go_wt_output_$i.txt 2>&1
    end=$(date +%s.%N)
    runtime=$(echo "$end - $start" | bc)
    go_wt_times+=($runtime)
    echo "  Run $i: ${runtime}s"
done

# Calculate Go weather-tool average
go_wt_avg=$(echo "scale=3; (${go_wt_times[0]} + ${go_wt_times[1]} + ${go_wt_times[2]} + ${go_wt_times[3]} + ${go_wt_times[4]} + ${go_wt_times[5]} + ${go_wt_times[6]} + ${go_wt_times[7]} + ${go_wt_times[8]}) / 9" | bc)

echo ""

# Run Python weather-tool 9 times
echo "Running Python weather-tool..."
py_wt_times=()
for i in 1 2 3 4 5 6 7 8 9; do
    start=$(date +%s.%N)
    cd langchain-agent && python weather-tool.py > /tmp/py_wt_output_$i.txt 2>&1
    cd ..
    end=$(date +%s.%N)
    runtime=$(echo "$end - $start" | bc)
    py_wt_times+=($runtime)
    echo "  Run $i: ${runtime}s"
done

# Calculate Python weather-tool average
py_wt_avg=$(echo "scale=3; (${py_wt_times[0]} + ${py_wt_times[1]} + ${py_wt_times[2]} + ${py_wt_times[3]} + ${py_wt_times[4]} + ${py_wt_times[5]} + ${py_wt_times[6]} + ${py_wt_times[7]} + ${py_wt_times[8]}) / 9" | bc)

echo ""
echo "-----------------------------------"
echo -e "Go weather-tool avg:     ${GREEN}${go_wt_avg}s${NC}"
echo -e "Python weather-tool avg: ${GREEN}${py_wt_avg}s${NC}"

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
# 3. MEMORY COMPARISON - Agents
# ========================================
echo -e "${BLUE}3. MEMORY COMPARISON - Agents${NC}"
echo "-----------------------------------"

# Go memory usage
echo "Measuring Go memory usage..."
/usr/bin/time -v ./simple-agent/simple-agent > /tmp/go_output.txt 2> /tmp/go_mem.txt
go_mem=$(grep "Maximum resident set size" /tmp/go_mem.txt | awk '{print $6}')
go_mem_mb=$(echo "scale=2; $go_mem / 1024" | bc)
echo -e "Go peak memory:     ${GREEN}${go_mem_mb} MB${NC}"

# Python memory usage
echo "Measuring Python memory usage..."
cd langchain-agent
/usr/bin/time -v python main.py > /tmp/py_output.txt 2> /tmp/py_mem.txt
cd ..
py_mem=$(grep "Maximum resident set size" /tmp/py_mem.txt | awk '{print $6}')
py_mem_mb=$(echo "scale=2; $py_mem / 1024" | bc)
echo -e "Python peak memory: ${GREEN}${py_mem_mb} MB${NC}"

echo ""
# ========================================
# 3b. MEMORY COMPARISON - Weather Tool
# ========================================
echo -e "${BLUE}3b. MEMORY COMPARISON - Weather Tool${NC}"
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

echo "Agents"
printf "%-22s %-15s %-15s\n" "Metric" "Go" "Python"
echo "-------------------------------------------------------"
printf "%-22s %-15s %-15s\n" "Binary/Script Size" "$go_size" "$py_size"
if [ -n "$py_total_size" ]; then
    printf "%-22s %-15s %-15s\n" "Python venv size" "-" "$py_total_size"
fi
printf "%-22s %-15s %-15s\n" "Avg Execution Time" "${go_avg}s" "${py_avg}s"
printf "%-22s %-15s %-15s\n" "Peak Memory" "${go_mem_mb} MB" "${py_mem_mb} MB"
echo ""

echo "Weather Tool"
printf "%-22s %-15s %-15s\n" "Metric" "Go" "Python"
echo "-------------------------------------------------------"
printf "%-22s %-15s %-15s\n" "Binary/Script Size" "$go_wt_size" "$py_wt_size"
if [ -n "$py_total_size" ]; then
    printf "%-22s %-15s %-15s\n" "Python venv size" "-" "$py_total_size"
fi
printf "%-22s %-15s %-15s\n" "Avg Execution Time" "${go_wt_avg}s" "${py_wt_avg}s"
printf "%-22s %-15s %-15s\n" "Peak Memory" "${go_wt_mem_mb} MB" "${py_wt_mem_mb} MB"
echo ""

# Cleanup
rm -f /tmp/go_output*.txt /tmp/py_output*.txt /tmp/go_mem.txt /tmp/py_mem.txt \
    /tmp/go_wt_output*.txt /tmp/py_wt_output*.txt /tmp/go_wt_mem.txt /tmp/py_wt_mem.txt

echo "Benchmark complete!"
