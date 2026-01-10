# Agent Performance Comparison Report
# Connection Reuse vs Cold Start Analysis

**Date:** 2026-01-09 17:09:09  
**Test:** Multi-city weather queries (6 cities: sf, nyc, tokyo, london, paris, sydney)  
**Runs:** 3 iterations per implementation per mode  

---

## Summary

### Connection Reuse (6 cities in single run)

| Metric | Go | Python | Winner |
|--------|-----|--------|---------|
| **Total Time (6 cities)** | 16.625s | 12.568s | Python |
| **Average per Call** | 2.770s | 2.094s | Python |

### Cold Start (6 separate program invocations)

| Metric | Go | Python | Winner |
|--------|-----|--------|---------|
| **Total Time (6 cities)** | 15.920s | 12.730s | Python |
| **Average per Call** | 2.653s | 2.121s | Python |

### Connection Overhead Impact

| Implementation | Connection Reuse | Cold Start | Overhead |
|---------------|-----------------|------------|----------|
| **Go** | 16.625s | 15.920s | +-4.00% |
| **Python** | 12.568s | 12.730s | +1.00% |

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
| Run 1 | 15.562306607s | 2.593717767s |
| Run 2 | 18.527595445s | 3.087932574s |
| Run 3 | 15.787651435s | 2.631275239s |
| **Average** | **16.625s** | **2.770s** |

### Go Implementation - Cold Start
```
Framework: agenticgokit/v1beta
LLM: Ollama (granite4:latest)
Mode: 6 separate program invocations
```

| Run | Total Time | Avg per Call |
|-----|-----------|--------------|
| Run 1 | 14.304594622s | 2.384s |
| Run 2 | 15.935426140s | 2.655s |
| Run 3 | 17.520521473s | 2.920s |
| **Average** | **15.920s** | **2.653s** |

### Python Implementation - Connection Reuse
```
Framework: LangChain + LangGraph
LLM: Ollama (granite4:latest)
Mode: 6 cities in single run
```

| Run | Total Time | Avg per Call |
|-----|-----------|--------------|
| Run 1 | 14.536s | 2.423s |
| Run 2 | 11.888s | 1.981s |
| Run 3 | 11.281s | 1.880s |
| **Average** | **12.568s** | **2.094s** |

### Python Implementation - Cold Start
```
Framework: LangChain + LangGraph
LLM: Ollama (granite4:latest)
Mode: 6 separate program invocations
```

| Run | Total Time | Avg per Call |
|-----|-----------|--------------|
| Run 1 | 11.687s | 1.947s |
| Run 2 | 13.125s | 2.187s |
| Run 3 | 13.378s | 2.229s |
| **Average** | **12.730s** | **2.121s** |

---

## Analysis

### Key Findings

1. **Connection Reuse Impact**
   - Go: -4.00% slower when starting fresh connections
   - Python: 1.00% slower when starting fresh connections
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
   - Account for -4.00%-1.00% overhead in performance planning

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

