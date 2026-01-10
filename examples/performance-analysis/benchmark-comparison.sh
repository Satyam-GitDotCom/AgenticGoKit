#!/bin/bash

# Benchmark Comparison Script - Go vs Python Agent Performance
# Compares multi-city weather agent performance between implementations

set -e

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_DIR="comparison_${TIMESTAMP}"
mkdir -p "$REPORT_DIR"

echo "======================================================================"
echo "  Agent Performance Comparison: Go vs Python"
echo "  Testing: Connection Reuse vs Cold Start"
echo "======================================================================"
echo ""
echo "Report directory: $REPORT_DIR"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# Build Go binary
# ============================================================================
echo -e "${BLUE}[1/4] Building Go agent...${NC}"
cd simple-agent
go build -o weather-profile weather-profile.go
cd ..
echo "✓ Go build complete"
echo ""

# ============================================================================
# Run Go benchmarks - Connection Reuse (6 cities in one run)
# ============================================================================
echo -e "${BLUE}[2/6] Running Go benchmarks - Connection Reuse (3 runs)...${NC}"
GO_REUSE_TIMES=()
for run in {1..3}; do
    echo "  Run $run/3..."
    OUTPUT=$(./simple-agent/weather-profile -v 2>&1)
    echo "$OUTPUT" > "$REPORT_DIR/go_reuse_run${run}.txt"
    
    # Extract total time
    TOTAL_TIME=$(echo "$OUTPUT" | grep "Total time:" | awk '{print $3}' | sed 's/s//')
    AVG_TIME=$(echo "$OUTPUT" | grep "Average per call:" | awk '{print $4}' | sed 's/s//')
    GO_REUSE_TIMES+=("$TOTAL_TIME:$AVG_TIME")
    
    echo "    Total: ${TOTAL_TIME}s, Average: ${AVG_TIME}s"
done
echo "✓ Go connection reuse benchmarks complete"
echo ""

# ============================================================================
# Run Go benchmarks - Cold Start (6 separate runs)
# ============================================================================
echo -e "${BLUE}[3/6] Running Go benchmarks - Cold Start (6 cities x 3 runs)...${NC}"
GO_COLD_TIMES=()
for run in {1..3}; do
    echo "  Run $run/3..."
    CITIES=("sf" "nyc" "tokyo" "london" "paris" "sydney")
    RUN_TOTAL=0
    for city in "${CITIES[@]}"; do
        OUTPUT=$(./simple-agent/weather-profile --city "$city" 2>&1)
        TIME=$(echo "$OUTPUT" | grep "Total time:" | awk '{print $3}' | sed 's/[^0-9.]//g')
        # Skip if TIME is empty
        if [ -n "$TIME" ]; then
            RUN_TOTAL=$(echo "$RUN_TOTAL + $TIME" | bc -l 2>/dev/null || echo "$RUN_TOTAL")
        fi
    done
    # Use bc with safe arithmetic
    AVG=$(echo "scale=3; $RUN_TOTAL / 6" | bc -l 2>/dev/null || echo "0")
    GO_COLD_TIMES+=("$RUN_TOTAL:$AVG")
    echo "$OUTPUT" > "$REPORT_DIR/go_cold_run${run}.txt"
    echo "    Total: ${RUN_TOTAL}s, Average: ${AVG}s"
done
echo "✓ Go cold start benchmarks complete"
echo ""

# ============================================================================
# Run Python benchmarks - Connection Reuse (6 cities in one run)
# ============================================================================
echo -e "${BLUE}[4/6] Running Python benchmarks - Connection Reuse (3 runs)...${NC}"
cd langchain-agent
PYTHON_REUSE_TIMES=()
for run in {1..3}; do
    echo "  Run $run/3..."
    OUTPUT=$(python3 weather-profile.py -v 2>&1)
    echo "$OUTPUT" > "../$REPORT_DIR/python_reuse_run${run}.txt"
    
    # Extract total time
    TOTAL_TIME=$(echo "$OUTPUT" | grep "Total time:" | awk '{print $3}' | sed 's/s//')
    AVG_TIME=$(echo "$OUTPUT" | grep "Average per call:" | awk '{print $4}' | sed 's/s//')
    PYTHON_REUSE_TIMES+=("$TOTAL_TIME:$AVG_TIME")
    
    echo "    Total: ${TOTAL_TIME}s, Average: ${AVG_TIME}s"
done
cd ..
echo "✓ Python connection reuse benchmarks complete"
echo ""

# ============================================================================
# Run Python benchmarks - Cold Start (6 separate runs)
# ============================================================================
echo -e "${BLUE}[5/6] Running Python benchmarks - Cold Start (6 cities x 3 runs)...${NC}"
cd langchain-agent
PYTHON_COLD_TIMES=()
for run in {1..3}; do
    echo "  Run $run/3..."
    CITIES=("sf" "nyc" "tokyo" "london" "paris" "sydney")
    RUN_TOTAL=0
    for city in "${CITIES[@]}"; do
        OUTPUT=$(python3 weather-profile.py --city "$city" 2>&1)
        TIME=$(echo "$OUTPUT" | grep "Total time:" | awk '{print $3}' | sed 's/[^0-9.]//g')
        # Skip if TIME is empty
        if [ -n "$TIME" ]; then
            RUN_TOTAL=$(echo "$RUN_TOTAL + $TIME" | bc -l 2>/dev/null || echo "$RUN_TOTAL")
        fi
    done
    # Use bc with safe arithmetic
    AVG=$(echo "scale=3; $RUN_TOTAL / 6" | bc -l 2>/dev/null || echo "0")
    PYTHON_COLD_TIMES+=("$RUN_TOTAL:$AVG")
    echo "$OUTPUT" > "../$REPORT_DIR/python_cold_run${run}.txt"
    echo "    Total: ${RUN_TOTAL}s, Average: ${AVG}s"
done
cd ..
echo "✓ Python cold start benchmarks complete"
echo ""

# ============================================================================
# Generate comparison report
# ============================================================================
echo -e "${BLUE}[6/6] Generating comparison report...${NC}"

# Calculate averages
calc_avg() {
    local sum=0
    local count=0
    for val in "$@"; do
        sum=$(echo "$sum + $val" | bc -l)
        count=$((count + 1))
    done
    echo "scale=3; $sum / $count" | bc -l
}

# Connection Reuse averages
GO_REUSE_TOTAL=$(calc_avg $(for i in "${GO_REUSE_TIMES[@]}"; do echo ${i%:*}; done))
GO_REUSE_AVG=$(calc_avg $(for i in "${GO_REUSE_TIMES[@]}"; do echo ${i#*:}; done))

PY_REUSE_TOTAL=$(calc_avg $(for i in "${PYTHON_REUSE_TIMES[@]}"; do echo ${i%:*}; done))
PY_REUSE_AVG=$(calc_avg $(for i in "${PYTHON_REUSE_TIMES[@]}"; do echo ${i#*:}; done))

# Cold Start averages
GO_COLD_TOTAL=$(calc_avg $(for i in "${GO_COLD_TIMES[@]}"; do echo ${i%:*}; done))
GO_COLD_AVG=$(calc_avg $(for i in "${GO_COLD_TIMES[@]}"; do echo ${i#*:}; done))

PY_COLD_TOTAL=$(calc_avg $(for i in "${PYTHON_COLD_TIMES[@]}"; do echo ${i%:*}; done))
PY_COLD_AVG=$(calc_avg $(for i in "${PYTHON_COLD_TIMES[@]}"; do echo ${i#*:}; done))

# Calculate overhead from cold starts
GO_OVERHEAD=$(echo "scale=2; (($GO_COLD_TOTAL - $GO_REUSE_TOTAL) / $GO_REUSE_TOTAL) * 100" | bc -l)
PY_OVERHEAD=$(echo "scale=2; (($PY_COLD_TOTAL - $PY_REUSE_TOTAL) / $PY_REUSE_TOTAL) * 100" | bc -l)

# Generate Markdown report
REPORT_FILE="$REPORT_DIR/COMPARISON_REPORT.md"

cat > "$REPORT_FILE" << EOF
# Agent Performance Comparison Report
# Connection Reuse vs Cold Start Analysis

**Date:** $(date '+%Y-%m-%d %H:%M:%S')  
**Test:** Multi-city weather queries (6 cities: sf, nyc, tokyo, london, paris, sydney)  
**Runs:** 3 iterations per implementation per mode  

---

## Summary

### Connection Reuse (6 cities in single run)

| Metric | Go | Python | Winner |
|--------|-----|--------|---------|
| **Total Time (6 cities)** | ${GO_REUSE_TOTAL}s | ${PY_REUSE_TOTAL}s | $([ $(echo "$GO_REUSE_TOTAL < $PY_REUSE_TOTAL" | bc -l) -eq 1 ] && echo "Go" || echo "Python") |
| **Average per Call** | ${GO_REUSE_AVG}s | ${PY_REUSE_AVG}s | $([ $(echo "$GO_REUSE_AVG < $PY_REUSE_AVG" | bc -l) -eq 1 ] && echo "Go" || echo "Python") |

### Cold Start (6 separate program invocations)

| Metric | Go | Python | Winner |
|--------|-----|--------|---------|
| **Total Time (6 cities)** | ${GO_COLD_TOTAL}s | ${PY_COLD_TOTAL}s | $([ $(echo "$GO_COLD_TOTAL < $PY_COLD_TOTAL" | bc -l) -eq 1 ] && echo "Go" || echo "Python") |
| **Average per Call** | ${GO_COLD_AVG}s | ${PY_COLD_AVG}s | $([ $(echo "$GO_COLD_AVG < $PY_COLD_AVG" | bc -l) -eq 1 ] && echo "Go" || echo "Python") |

### Connection Overhead Impact

| Implementation | Connection Reuse | Cold Start | Overhead |
|---------------|-----------------|------------|----------|
| **Go** | ${GO_REUSE_TOTAL}s | ${GO_COLD_TOTAL}s | +${GO_OVERHEAD}% |
| **Python** | ${PY_REUSE_TOTAL}s | ${PY_COLD_TOTAL}s | +${PY_OVERHEAD}% |

---

## Detailed Results

### Go Implementation - Connection Reuse
\`\`\`
Framework: agenticgokit/v1beta
LLM: Ollama (granite4:latest)
Mode: 6 cities in single run
\`\`\`

| Run | Total Time | Avg per Call |
|-----|-----------|--------------|
EOF

# Add Go reuse results
for i in {1..3}; do
    IFS=':' read -r total avg <<< "${GO_REUSE_TIMES[$((i-1))]}"
    echo "| Run $i | ${total}s | ${avg}s |" >> "$REPORT_FILE"
done

cat >> "$REPORT_FILE" << EOF
| **Average** | **${GO_REUSE_TOTAL}s** | **${GO_REUSE_AVG}s** |

### Go Implementation - Cold Start
\`\`\`
Framework: agenticgokit/v1beta
LLM: Ollama (granite4:latest)
Mode: 6 separate program invocations
\`\`\`

| Run | Total Time | Avg per Call |
|-----|-----------|--------------|
EOF

# Add Go cold results
for i in {1..3}; do
    IFS=':' read -r total avg <<< "${GO_COLD_TIMES[$((i-1))]}"
    echo "| Run $i | ${total}s | ${avg}s |" >> "$REPORT_FILE"
done

cat >> "$REPORT_FILE" << EOF
| **Average** | **${GO_COLD_TOTAL}s** | **${GO_COLD_AVG}s** |

### Python Implementation - Connection Reuse
\`\`\`
Framework: LangChain + LangGraph
LLM: Ollama (granite4:latest)
Mode: 6 cities in single run
\`\`\`

| Run | Total Time | Avg per Call |
|-----|-----------|--------------|
EOF

# Add Python reuse results
for i in {1..3}; do
    IFS=':' read -r total avg <<< "${PYTHON_REUSE_TIMES[$((i-1))]}"
    echo "| Run $i | ${total}s | ${avg}s |" >> "$REPORT_FILE"
done

cat >> "$REPORT_FILE" << EOF
| **Average** | **${PY_REUSE_TOTAL}s** | **${PY_REUSE_AVG}s** |

### Python Implementation - Cold Start
\`\`\`
Framework: LangChain + LangGraph
LLM: Ollama (granite4:latest)
Mode: 6 separate program invocations
\`\`\`

| Run | Total Time | Avg per Call |
|-----|-----------|--------------|
EOF

# Add Python cold results
for i in {1..3}; do
    IFS=':' read -r total avg <<< "${PYTHON_COLD_TIMES[$((i-1))]}"
    echo "| Run $i | ${total}s | ${avg}s |" >> "$REPORT_FILE"
done

cat >> "$REPORT_FILE" << EOF
| **Average** | **${PY_COLD_TOTAL}s** | **${PY_COLD_AVG}s** |

---

## Analysis

### Key Findings

1. **Connection Reuse Impact**
   - Go: ${GO_OVERHEAD}% slower when starting fresh connections
   - Python: ${PY_OVERHEAD}% slower when starting fresh connections
   - Connection pooling provides significant performance benefit

2. **Cold Start Characteristics**
   - Each invocation requires: HTTP connection setup, TLS handshake, agent initialization
   - No benefit from keeping model warm in GPU VRAM between runs
   - Demonstrates pure per-request overhead

3. **Framework Comparison**
   - Connection reuse scenario shows framework efficiency when connections are warm
   - Cold start scenario shows initialization overhead and connection setup costs
   - Difference reveals how well each framework manages HTTP client lifecycle

### Recommendations

1. **For Production Workloads:**
   - Always use connection reuse mode (long-running service)
   - Keep HTTP clients alive between requests
   - Configure Ollama keep-alive settings appropriately

2. **Connection Management:**
   - Go: Ensure \`http.Client\` Transport MaxIdleConns is set appropriately
   - Python: Configure httpx connection pool limits
   - Monitor connection pool metrics

3. **When Cold Starts Are Unavoidable:**
   - Serverless/FaaS environments may force cold starts
   - Consider keeping warm instances or pre-warming connections
   - Account for ${GO_OVERHEAD}%-${PY_OVERHEAD}% overhead in performance planning

---

## Environment

- **OS:** $(uname -s) $(uname -r)
- **Go Version:** $(go version | awk '{print $3}')
- **Python Version:** $(python3 --version | awk '{print $2}')
- **Ollama Model:** granite4:latest
- **Test Configuration:** Temperature 0.0, MaxTokens 150

---

## Raw Output Files

Individual run outputs saved in:
- Go Connection Reuse: \`go_reuse_run{1,2,3}.txt\`
- Go Cold Start: \`go_cold_run{1,2,3}.txt\`
- Python Connection Reuse: \`python_reuse_run{1,2,3}.txt\`
- Python Cold Start: \`python_cold_run{1,2,3}.txt\`

EOF

echo "✓ Report generated: $REPORT_FILE"
echo ""

# ============================================================================
# Display summary
# ============================================================================
echo -e "${GREEN}======================================================================"
echo "  Benchmark Complete!"
echo "======================================================================"
echo "  Connection Reuse Mode:"
echo "    Go:     ${GO_REUSE_TOTAL}s total, ${GO_REUSE_AVG}s per call"
echo "    Python: ${PY_REUSE_TOTAL}s total, ${PY_REUSE_AVG}s per call"
echo ""
echo "  Cold Start Mode:"
echo "    Go:     ${GO_COLD_TOTAL}s total, ${GO_COLD_AVG}s per call (+${GO_OVERHEAD}%)"
echo "    Python: ${PY_COLD_TOTAL}s total, ${PY_COLD_AVG}s per call (+${PY_OVERHEAD}%)"
echo ""
echo "  Full report: $REPORT_FILE"
echo "======================================================================${NC}"
echo ""
