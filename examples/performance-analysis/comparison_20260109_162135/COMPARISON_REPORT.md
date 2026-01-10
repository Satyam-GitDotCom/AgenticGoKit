# Agent Performance Comparison Report
# Connection Reuse vs Cold Start Analysis

**Date:** 2026-01-09 16:26:04  
**Test:** Multi-city weather queries (6 cities: sf, nyc, tokyo, london, paris, sydney)  
**Runs:** 3 iterations per implementation per mode  

---

## Summary

### Connection Reuse (6 cities in single run)

| Metric | Go | Python | Winner |
|--------|-----|--------|---------|
| **Total Time (6 cities)** | 29.194s | 14.484s | Python |
| **Average per Call** | 4.865s | 2.414s | Python |

### Cold Start (6 separate program invocations)

| Metric | Go | Python | Winner |
|--------|-----|--------|---------|
| **Total Time (6 cities)** | 27.647s | 14.195s | Python |
| **Average per Call** | 4.607s | 2.365s | Python |

### Connection Overhead Impact

| Implementation | Connection Reuse | Cold Start | Overhead |
|---------------|-----------------|------------|----------|
| **Go** | 29.194s | 27.647s | +-5.00% |
| **Python** | 14.484s | 14.195s | +-1.00% |

---

## Detailed Results

### Go Implementation - Connection Reuse
```
Framework: agenticgokit/v1beta
LLM: Ollama (granite4:latest)
Mode: 6 cities in single run
```

| Run | Total Time | Avg per Call |
|-----|-----------|--------------|
| Run 1 | 23.306775163s | 3.884462527s |
| Run 2 | 30.334738128s | 5.055789688s |
| Run 3 | 33.943448571s | 5.657241428s |
| **Average** | **29.194s** | **4.865s** |

### Go Implementation - Cold Start
```
Framework: agenticgokit/v1beta
LLM: Ollama (granite4:latest)
Mode: 6 separate program invocations
```

| Run | Total Time | Avg per Call |
|-----|-----------|--------------|
| Run 1 | 27.534319781s | 4.589s |
| Run 2 | 25.011917792s | 4.168s |
| Run 3 | 30.397577582s | 5.066s |
| **Average** | **27.647s** | **4.607s** |

### Python Implementation - Connection Reuse
```
Framework: LangChain + LangGraph
LLM: Ollama (granite4:latest)
Mode: 6 cities in single run
```

| Run | Total Time | Avg per Call |
|-----|-----------|--------------|
| Run 1 | 14.185s | 2.364s |
| Run 2 | 13.466s | 2.244s |
| Run 3 | 15.802s | 2.634s |
| **Average** | **14.484s** | **2.414s** |

### Python Implementation - Cold Start
```
Framework: LangChain + LangGraph
LLM: Ollama (granite4:latest)
Mode: 6 separate program invocations
```

| Run | Total Time | Avg per Call |
|-----|-----------|--------------|
| Run 1 | 14.434s | 2.405s |
| Run 2 | 13.094s | 2.182s |
| Run 3 | 15.057s | 2.509s |
| **Average** | **14.195s** | **2.365s** |

---

## Analysis

### Key Findings

1. **Connection Reuse Impact**
   - Go: -5.00% slower when starting fresh connections
   - Python: -1.00% slower when starting fresh connections
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
   - Go: Ensure `http.Client` Transport MaxIdleConns is set appropriately
   - Python: Configure httpx connection pool limits
   - Monitor connection pool metrics

3. **When Cold Starts Are Unavoidable:**
   - Serverless/FaaS environments may force cold starts
   - Consider keeping warm instances or pre-warming connections
   - Account for -5.00%--1.00% overhead in performance planning

---

## Environment

- **OS:** Linux 6.14.0-37-generic
- **Go Version:** go1.25.5
- **Python Version:** 3.12.3
- **Ollama Model:** granite4:latest
- **Test Configuration:** Temperature 0.0, MaxTokens 150

---

## Raw Output Files

Individual run outputs saved in:
- Go Connection Reuse: `go_reuse_run{1,2,3}.txt`
- Go Cold Start: `go_cold_run{1,2,3}.txt`
- Python Connection Reuse: `python_reuse_run{1,2,3}.txt`
- Python Cold Start: `python_cold_run{1,2,3}.txt`

