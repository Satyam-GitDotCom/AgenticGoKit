# Agent Performance Comparison Report
# Connection Reuse vs Cold Start Analysis

**Date:** 2026-01-10 03:40:08  
**Test:** Multi-city weather queries (6 cities: sf, nyc, tokyo, london, paris, sydney)  
**Runs:** 3 iterations per implementation per mode  

---

## Summary

### Connection Reuse (6 cities in single run)

| Metric | Go | Python | Winner |
|--------|-----|--------|---------|
| **Total Time (6 cities)** | 9.207s | 17.758s | Go |
| **Average per Call** | 1.534s | 2.959s | Go |

### Cold Start (6 separate program invocations)

| Metric | Go | Python | Winner |
|--------|-----|--------|---------|
| **Total Time (6 cities)** | 9.422s | 22.622s | Go |
| **Average per Call** | 1.570s | 3.770s | Go |

### Connection Overhead Impact

| Implementation | Connection Reuse | Cold Start | Overhead |
|---------------|-----------------|------------|----------|
| **Go** | 9.207s | 9.422s | +2.00% |
| **Python** | 17.758s | 22.622s | +27.00% |

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
| Run 1 | 10.599930925s | 1.766655154s |
| Run 2 | 8.554066031s | 1.425677671s |
| Run 3 | 8.469850619s | 1.411641769s |
| **Average** | **9.207s** | **1.534s** |

### Go Implementation - Cold Start
```
Framework: agenticgokit/v1beta
LLM: Ollama (granite4:latest)
Mode: 6 separate program invocations
```

| Run | Total Time | Avg per Call |
|-----|-----------|--------------|
| Run 1 | 9.391383496s | 1.565s |
| Run 2 | 9.792952003s | 1.632s |
| Run 3 | 9.083036177s | 1.513s |
| **Average** | **9.422s** | **1.570s** |

### Python Implementation - Connection Reuse
```
Framework: LangChain + LangGraph
LLM: Ollama (granite4:latest)
Mode: 6 cities in single run
```

| Run | Total Time | Avg per Call |
|-----|-----------|--------------|
| Run 1 | 19.279s | 3.213s |
| Run 2 | 16.381s | 2.730s |
| Run 3 | 17.616s | 2.936s |
| **Average** | **17.758s** | **2.959s** |

### Python Implementation - Cold Start
```
Framework: LangChain + LangGraph
LLM: Ollama (granite4:latest)
Mode: 6 separate program invocations
```

| Run | Total Time | Avg per Call |
|-----|-----------|--------------|
| Run 1 | 19.884s | 3.314s |
| Run 2 | 23.273s | 3.878s |
| Run 3 | 24.710s | 4.118s |
| **Average** | **22.622s** | **3.770s** |

---

## Analysis

### Key Findings

1. **Connection Reuse Impact**
   - Go: 2.00% slower when starting fresh connections
   - Python: 27.00% slower when starting fresh connections
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
   - Account for 2.00%-27.00% overhead in performance planning

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

