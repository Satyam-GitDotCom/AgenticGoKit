# Agent Performance Comparison Report
# Connection Reuse vs Cold Start Analysis

**Date:** 2026-01-09 17:29:12  
**Test:** Multi-city weather queries (6 cities: sf, nyc, tokyo, london, paris, sydney)  
**Runs:** 3 iterations per implementation per mode  

---

## Summary

### Connection Reuse (6 cities in single run)

| Metric | Go | Python | Winner |
|--------|-----|--------|---------|
| **Total Time (6 cities)** | 5.706s | 12.626s | Go |
| **Average per Call** | s | 2.104s | Python |

### Cold Start (6 separate program invocations)

| Metric | Go | Python | Winner |
|--------|-----|--------|---------|
| **Total Time (6 cities)** | 3180.372s | 12.843s | Python |
| **Average per Call** | 530.061s | 2.140s | Python |

### Connection Overhead Impact

| Implementation | Connection Reuse | Cold Start | Overhead |
|---------------|-----------------|------------|----------|
| **Go** | 5.706s | 3180.372s | +55637.00% |
| **Python** | 12.626s | 12.843s | +1.00% |

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
| Run 1 | 5.766948452s | 961.158075ms |
| Run 2 | 5.689188166s | 948.198027ms |
| Run 3 | 5.663862825s | 943.977137ms |
| **Average** | **5.706s** | **s** |

### Go Implementation - Cold Start
```
Framework: agenticgokit/v1beta
LLM: Ollama (granite4:latest)
Mode: 6 separate program invocations
```

| Run | Total Time | Avg per Call |
|-----|-----------|--------------|
| Run 1 | 3805.115251971s | 634.185s |
| Run 2 | 1910.790219085s | 318.465s |
| Run 3 | 3825.213079626s | 637.535s |
| **Average** | **3180.372s** | **530.061s** |

### Python Implementation - Connection Reuse
```
Framework: LangChain + LangGraph
LLM: Ollama (granite4:latest)
Mode: 6 cities in single run
```

| Run | Total Time | Avg per Call |
|-----|-----------|--------------|
| Run 1 | 12.250s | 2.042s |
| Run 2 | 13.479s | 2.246s |
| Run 3 | 12.149s | 2.025s |
| **Average** | **12.626s** | **2.104s** |

### Python Implementation - Cold Start
```
Framework: LangChain + LangGraph
LLM: Ollama (granite4:latest)
Mode: 6 separate program invocations
```

| Run | Total Time | Avg per Call |
|-----|-----------|--------------|
| Run 1 | 13.987s | 2.331s |
| Run 2 | 11.786s | 1.964s |
| Run 3 | 12.757s | 2.126s |
| **Average** | **12.843s** | **2.140s** |

---

## Analysis

### Key Findings

1. **Connection Reuse Impact**
   - Go: 55637.00% slower when starting fresh connections
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
   - Account for 55637.00%-1.00% overhead in performance planning

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

