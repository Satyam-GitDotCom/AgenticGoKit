#!/bin/bash

# Compare consistency between Go and Python weather tools

RUNS=${1:-10}

echo "========================================="
echo "  Go vs Python Consistency Comparison"
echo "========================================="
echo "Running $RUNS iterations of each..."
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Ensure Go binary is built
if [ ! -f "simple-agent/weather-tool" ]; then
    echo "Building Go weather-tool..."
    cd simple-agent && go build -o weather-tool weather-tool.go && cd ..
fi

# Arrays to store results
declare -a go_times
declare -a py_times

echo -e "${BLUE}Running Go weather-tool ($RUNS times)...${NC}"
echo "-----------------------------------"
for i in $(seq 1 $RUNS); do
    start=$(date +%s.%N)
    ./simple-agent/weather-tool > /dev/null 2>&1
    end=$(date +%s.%N)
    runtime=$(echo "$end - $start" | bc)
    go_times[$i]=$runtime
    printf "  Run %2d: %ss\n" $i "$runtime"
done

echo ""
echo -e "${BLUE}Running Python weather-tool ($RUNS times)...${NC}"
echo "-----------------------------------"
for i in $(seq 1 $RUNS); do
    start=$(date +%s.%N)
    cd langchain-agent && python weather-tool.py > /dev/null 2>&1
    cd ..
    end=$(date +%s.%N)
    runtime=$(echo "$end - $start" | bc)
    py_times[$i]=$runtime
    printf "  Run %2d: %ss\n" $i "$runtime"
done

# Calculate statistics for Go
go_min=${go_times[1]}
go_max=${go_times[1]}
go_total=0
for i in $(seq 1 $RUNS); do
    t=${go_times[$i]}
    go_total=$(echo "$go_total + $t" | bc)
    if (( $(echo "$t < $go_min" | bc -l) )); then
        go_min=$t
    fi
    if (( $(echo "$t > $go_max" | bc -l) )); then
        go_max=$t
    fi
done
go_avg=$(echo "scale=3; $go_total / $RUNS" | bc)
go_variance=$(echo "scale=3; $go_max - $go_min" | bc)
go_ratio=$(echo "scale=2; $go_max / $go_min" | bc)

# Sort for median
IFS=$'\n' go_sorted=($(sort -n <<<"${go_times[*]}"))
unset IFS
go_median_idx=$(( ($RUNS + 1) / 2 ))
go_median=${go_sorted[$go_median_idx]}

# Calculate standard deviation for Go
go_var_sum=0
for i in $(seq 1 $RUNS); do
    diff=$(echo "${go_times[$i]} - $go_avg" | bc)
    sq=$(echo "$diff * $diff" | bc)
    go_var_sum=$(echo "$go_var_sum + $sq" | bc)
done
go_stddev=$(echo "scale=3; sqrt($go_var_sum / $RUNS)" | bc)

# Calculate statistics for Python
py_min=${py_times[1]}
py_max=${py_times[1]}
py_total=0
for i in $(seq 1 $RUNS); do
    t=${py_times[$i]}
    py_total=$(echo "$py_total + $t" | bc)
    if (( $(echo "$t < $py_min" | bc -l) )); then
        py_min=$t
    fi
    if (( $(echo "$t > $py_max" | bc -l) )); then
        py_max=$t
    fi
done
py_avg=$(echo "scale=3; $py_total / $RUNS" | bc)
py_variance=$(echo "scale=3; $py_max - $py_min" | bc)
py_ratio=$(echo "scale=2; $py_max / $py_min" | bc)

# Sort for median
IFS=$'\n' py_sorted=($(sort -n <<<"${py_times[*]}"))
unset IFS
py_median_idx=$(( ($RUNS + 1) / 2 ))
py_median=${py_sorted[$py_median_idx]}

# Calculate standard deviation for Python
py_var_sum=0
for i in $(seq 1 $RUNS); do
    diff=$(echo "${py_times[$i]} - $py_avg" | bc)
    sq=$(echo "$diff * $diff" | bc)
    py_var_sum=$(echo "$py_var_sum + $sq" | bc)
done
py_stddev=$(echo "scale=3; sqrt($py_var_sum / $RUNS)" | bc)

echo ""
echo "========================================="
echo "  Consistency Analysis"
echo "========================================="
echo ""

printf "%-25s %-15s %-15s\n" "Metric" "Go" "Python"
echo "-------------------------------------------------------"
printf "%-25s %-15s %-15s\n" "Min Time" "${go_min}s" "${py_min}s"
printf "%-25s %-15s %-15s\n" "Max Time" "${go_max}s" "${py_max}s"
printf "%-25s %-15s %-15s\n" "Median Time" "${go_median}s" "${py_median}s"
printf "%-25s %-15s %-15s\n" "Avg Time" "${go_avg}s" "${py_avg}s"
echo "-------------------------------------------------------"
printf "%-25s ${YELLOW}%-15s${NC} ${YELLOW}%-15s${NC}\n" "Range (max-min)" "${go_variance}s" "${py_variance}s"
printf "%-25s ${YELLOW}%-15s${NC} ${YELLOW}%-15s${NC}\n" "Ratio (max/min)" "${go_ratio}x" "${py_ratio}x"
printf "%-25s ${YELLOW}%-15s${NC} ${YELLOW}%-15s${NC}\n" "Std Deviation" "${go_stddev}s" "${py_stddev}s"
echo ""

# Calculate coefficient of variation (CV) - stddev/mean
go_cv=$(echo "scale=2; ($go_stddev / $go_avg) * 100" | bc)
py_cv=$(echo "scale=2; ($py_stddev / $py_avg) * 100" | bc)

printf "%-25s ${YELLOW}%-15s${NC} ${YELLOW}%-15s${NC}\n" "Coeff. of Variation" "${go_cv}%" "${py_cv}%"

echo ""
echo "Interpretation:"
echo "-----------------------------------"
if (( $(echo "$go_cv > $py_cv" | bc -l) )); then
    diff=$(echo "scale=1; $go_cv - $py_cv" | bc)
    echo -e "${GREEN}Python is more consistent (${diff}% less variance)${NC}"
else
    diff=$(echo "scale=1; $py_cv - $go_cv" | bc)
    echo -e "${YELLOW}Go is more consistent (${diff}% less variance)${NC}"
fi

if (( $(echo "$go_avg < $py_avg" | bc -l) )); then
    speedup=$(echo "scale=2; $py_avg / $go_avg" | bc)
    echo -e "${GREEN}Go is ${speedup}x faster on average${NC}"
else
    speedup=$(echo "scale=2; $go_avg / $py_avg" | bc)
    echo -e "${YELLOW}Python is ${speedup}x faster on average${NC}"
fi

# Detect bimodal distribution for Go
fast_count=0
slow_count=0
threshold=$(echo "scale=3; ($go_min + $go_max) / 2" | bc)

for i in $(seq 1 $RUNS); do
    if (( $(echo "${go_times[$i]} < $threshold" | bc -l) )); then
        fast_count=$((fast_count + 1))
    else
        slow_count=$((slow_count + 1))
    fi
done

echo ""
echo "Go Distribution Analysis:"
echo "  Fast runs (<${threshold}s): $fast_count"
echo "  Slow runs (≥${threshold}s): $slow_count"

if [ $fast_count -gt 0 ] && [ $slow_count -gt 0 ]; then
    echo -e "  ${YELLOW}Bimodal distribution detected!${NC}"
    echo "  → Suggests model loading/unloading between runs"
fi

echo ""
echo "========================================="
echo "  Why is Python More Consistent?"
echo "========================================="
echo ""
echo "Possible reasons:"
echo "  1. HTTP keep-alive / connection pooling"
echo "  2. Langchain-specific Ollama optimizations"
echo "  3. Different request patterns/batching"
echo "  4. Python's GIL preventing concurrent unloading"
echo ""
echo "Next steps to investigate:"
echo "  - Check HTTP connection behavior"
echo "  - Monitor Ollama model loading/unloading"
echo "  - Compare network traffic patterns"
echo ""
