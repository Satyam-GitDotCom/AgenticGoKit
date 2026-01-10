# Agent Performance Comparison Report
# Connection Reuse vs Cold Start Analysis

**Date:** 2026-01-09 17:59:39  
**Test:** Multi-city weather queries (6 cities: sf, nyc, tokyo, london, paris, sydney)  
**Runs:** 3 iterations per implementation per mode  

---

## Summary

### Connection Reuse (6 cities in single run)

| Metric | Go | Python | Winner |
|--------|-----|--------|---------|
| **Total Time (6 cities)** | 9.891s | 18.202s | Go |
| **Average per Call** | 1.648s | 3.034s | Go |

### Cold Start (6 separate program invocations)

| Metric | Go | Python | Winner |
|--------|-----|--------|---------|
| **Total Time (6 cities)** | 8.412s | 26.388s | Go |
| **Average per Call** | 1.401s | 4.397s | Go |

### Connection Overhead Impact

| Implementation | Connection Reuse | Cold Start | Overhead |
|---------------|-----------------|------------|----------|
| **Go** | 9.891s | 8.412s | +-14.00% |
| **Python** | 18.202s | 26.388s | +44.00% |

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
| Run 1 | 14.98175665s | 2.496959441s |
| Run 2 | 7.37107271s | 1.228512118s |
| Run 3 | 7.320702327s | 1.220117054s |
| **Average** | **9.891s** | **1.648s** |

### Go Implementation - Cold Start
```
Framework: agenticgokit/v1beta
LLM: Ollama (granite4:latest)
Mode: 6 separate program invocations
```

| Run | Total Time | Avg per Call |
|-----|-----------|--------------|
| Run 1 | 8.432393730s | 1.405s |
| Run 2 | 8.220816536s | 1.370s |
| Run 3 | 8.585016793s | 1.430s |
| **Average** | **8.412s** | **1.401s** |

### Python Implementation - Connection Reuse
```
Framework: LangChain + LangGraph
LLM: Ollama (granite4:latest)
Mode: 6 cities in single run
```

| Run | Total Time | Avg per Call |
|-----|-----------|--------------|
| Run 1 | 19.344s | 3.224s |
| Run 2 | 18.748s | 3.125s |
| Run 3 | 16.516s | 2.753s |
| **Average** | **18.202s** | **3.034s** |

### Python Implementation - Cold Start
```
Framework: LangChain + LangGraph
LLM: Ollama (granite4:latest)
Mode: 6 separate program invocations
```

| Run | Total Time | Avg per Call |
|-----|-----------|--------------|
| Run 1 | 24.870s | 4.145s |
| Run 2 | 24.111s | 4.018s |
| Run 3 | 30.184s | 5.030s |
| **Average** | **26.388s** | **4.397s** |

---

## Analysis

### Key Findings

1. **Connection Reuse Impact**
   - Go: -14.00% slower when starting fresh connections
   - Python: 44.00% slower when starting fresh connections
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
   - Account for -14.00%-44.00% overhead in performance planning

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

