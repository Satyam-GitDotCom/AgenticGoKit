# Observability Guide

Get complete visibility into your agent's behavior with built-in observability. Track LLM calls, agent execution, tool usage, multi-agent workflows, and subworkflow nesting through distributed tracing and structured logging.

---

## What You Get

- **Distributed Tracing**: OpenTelemetry-based spans for all operations
- **Workflow Visibility**: Complete control flow for Sequential, Parallel, DAG, and Loop workflows
- **Subworkflow Tracking**: Hierarchical nesting with depth and path tracking
- **LLM Observability**: Token usage, latency, costs across 8+ providers
- **Tool Instrumentation**: Native tool and MCP tool execution metrics
- **Structured Logging**: Correlated logs with trace IDs
- **Multiple Exporters**: Console, File (JSONL), OTLP (Jaeger, Tempo, etc.)
- **Zero Overhead**: Completely disable when not needed

---

## Quick Start

### Enable Observability (Environment Variables - Recommended)

```go
package main

import (
    "context"
    "log"
    "os"
    
    "github.com/agenticgokit/agenticgokit/v1beta"
)

func main() {
    // Enable tracing via environment variable
    os.Setenv("AGK_TRACE", "true")
    
    // Create agent - tracing automatically enabled
    agent, err := v1beta.NewChatAgent("Assistant",
        v1beta.WithLLM("openai", "gpt-4"),
    )
    if err != nil {
        log.Fatal(err)
    }
    
    // Run agent - traces automatically captured
    result, err := agent.Run(context.Background(), "What is 2+2?")
    if err != nil {
        log.Fatal(err)
    }
    
    log.Printf("Result: %s", result.Content)
}
```

### Enable Observability (Builder Pattern)

```go
// Use Builder pattern for more control
agent, err := v1beta.NewBuilder("Assistant").
    WithObservability("my-service", "1.0.0").  // serviceName, serviceVersion
    Build()
```

### View Traces

```bash
# List all runs
agk trace list

# Show specific trace
agk trace show <run-id>

# View in Jaeger UI
agk trace view <run-id>

# Export to JSON
agk trace export <run-id> --format json
```

---

## Configuration

Observability is configured through **environment variables**. This is the primary and recommended method.

### Environment Variables

```bash
# Enable tracing (required)
export AGK_TRACE=true

# Set exporter type (optional, default: file)
export AGK_TRACE_EXPORTER=otlp  # Options: console, file, otlp

# OTLP endpoint (for otlp exporter)
export AGK_TRACE_ENDPOINT=http://localhost:4318

# File path (for file exporter, auto-generated if not set)
export AGK_TRACE_FILEPATH=.agk/runs/trace.jsonl

# Sample rate: 0.0 to 1.0 (optional, default: 1.0)
export AGK_TRACE_SAMPLE=1.0  # 1.0 = 100%, 0.1 = 10%

# Environment name (optional, default: dev)
export AGK_ENV=production
```

### Builder Method (Alternative)

For programmatic control when using `NewBuilder()`:

```go
agent, err := v1beta.NewBuilder("MyAgent").
    WithObservability("my-service", "1.0.0").
    Build()
if err != nil {
    log.Fatal(err)
}

// Important: Call cleanup to flush traces
defer agent.Cleanup(context.Background())
```

**Note:** The `WithObservability()` method is only available on the `Builder` interface, **NOT** as an `Option` for `NewChatAgent()`, `NewResearchAgent()`, etc. For these factory functions, use environment variables.

---

## What Gets Traced

### Agent Execution

Every agent run creates a root span:

```
agk.agent.run (1200ms)
├─ agk.agent.name: "Assistant"
├─ agk.agent.input_bytes: 256
├─ agk.agent.output_bytes: 512
├─ agk.agent.success: true
└─ agk.agent.total_tokens: 150
```

### LLM Calls

All LLM interactions are instrumented:

```
llm.openai.call (800ms)
├─ llm.provider: "openai"
├─ llm.model: "gpt-4"
├─ llm.temperature: 0.7
├─ llm.max_tokens: 2048
├─ llm.prompt_tokens: 100
├─ llm.completion_tokens: 50
├─ llm.total_tokens: 150
├─ llm.latency_ms: 800
└─ llm.success: true
```

**Supported Providers:** OpenAI, Azure OpenAI, Anthropic, Ollama, OpenRouter, HuggingFace, vLLM, MLFlow, BentoML

### Tool Execution

Native tool calls:

```
agk.tool.call (150ms)
├─ agk.tool.name: "calculator"
├─ agk.tool.input_bytes: 32
├─ agk.tool.output_bytes: 16
├─ agk.tool.latency_ms: 150
└─ agk.tool.success: true
```

MCP tool calls:

```
agk.mcp.tool.call (200ms)
├─ agk.tool.name: "filesystem_read"
├─ agk.mcp.server: "filesystem-server"
├─ agk.mcp.tool.input_bytes: 64
├─ agk.mcp.tool.output_bytes: 1024
├─ agk.mcp.tool.latency_ms: 200
├─ agk.mcp.tool.content_count: 1
└─ agk.mcp.tool.success: true
```

### Workflow Execution

#### Sequential Workflow

```
agk.workflow.sequential (1000ms)
├─ agk.workflow.mode: "sequential"
├─ agk.workflow.step_count: 3
├─ agk.workflow.completed_steps: 3
├─ agk.workflow.success: true
└─ Steps:
   ├── agk.workflow.step: "extract" (300ms)
   │   ├─ agk.workflow.step_name: "extract"
   │   ├─ agk.workflow.step_index: 0
   │   ├─ agk.workflow.input_bytes: 256
   │   ├─ agk.workflow.output_bytes: 512
   │   └─ agk.agent.run (280ms)
   │
   ├── agk.workflow.step: "transform" (400ms)
   │   └─ agk.agent.run (380ms)
   │
   └── agk.workflow.step: "load" (300ms)
       └─ agk.agent.run (280ms)
```

#### Parallel Workflow

```
agk.workflow.parallel (600ms)
├─ agk.workflow.mode: "parallel"
├─ agk.workflow.step_count: 3
└─ Steps (concurrent):
   ├── agk.workflow.step: "sentiment" (400ms)
   ├── agk.workflow.step: "entities" (350ms)
   ├── agk.workflow.step: "topics" (200ms)
   └── agk.workflow.sync (0ms)  // Synchronization overhead
```

#### DAG Workflow

```
agk.workflow.dag (1500ms)
├─ agk.workflow.mode: "dag"
├─ agk.workflow.step_count: 5
└─ Stages:
   ├── agk.workflow.stage: #1 (200ms)
   │   ├─ agk.workflow.step: "collect"
   │   └─ Dependencies: none
   │
   ├── agk.workflow.stage: #2 (400ms - parallel)
   │   ├─ agk.workflow.step: "process1"
   │   ├─ agk.workflow.step: "process2"
   │   └─ Dependencies: ["collect"]
   │
   └── agk.workflow.stage: #3 (300ms)
       ├─ agk.workflow.step: "aggregate"
       └─ Dependencies: ["process1", "process2"]
```

#### Loop Workflow

```
agk.workflow.loop (2000ms)
├─ agk.workflow.mode: "loop"
├─ agk.workflow.max_iterations: 5
└─ Iterations:
   ├── agk.workflow.iteration: #1 (420ms)
   │   ├─ agk.agent.run (400ms)
   │   └─ agk.workflow.condition_check (20ms)
   │       └─ condition_satisfied: false
   │
   ├── agk.workflow.iteration: #2 (380ms)
   │   ├─ agk.agent.run (360ms)
   │   └─ agk.workflow.condition_check (20ms)
   │       └─ condition_satisfied: true
   │
   └─ agk.workflow.exit_reason: "condition_met"
```

### Subworkflow Composition

Hierarchical workflow nesting:

```
agk.workflow.sequential: "main" (1800ms)
├─ agk.workflow.step: "research" (1000ms)
│  └─ agk.subworkflow.run: "research" (980ms)
│     ├─ agk.subworkflow.name: "research"
│     ├─ agk.subworkflow.path: "main/research"
│     ├─ agk.subworkflow.depth: 1
│     ├─ agk.subworkflow.workflow_mode: "parallel"
│     └─ agk.workflow.parallel (960ms)
│        ├── agk.workflow.step: "web_search"
│        ├── agk.workflow.step: "db_query"
│        └── agk.workflow.sync
│
├─ agk.workflow.step: "analyze" (500ms)
│  └─ agk.agent.run (480ms)
│
└─ agk.workflow.step: "summarize" (300ms)
   └─ agk.agent.run (280ms)
```

---

## Exporters

### Console Exporter

Pretty-print spans to stdout. Great for development:

```bash
export AGK_TRACE=true
export AGK_TRACE_EXPORTER=console
```

```go
agent, err := v1beta.NewChatAgent("Assistant",
    v1beta.WithLLM("openai", "gpt-4"),
)
```

**Output:** JSON-formatted spans to console

### File Exporter (Default)

Store traces as JSONL for offline analysis:

```bash
export AGK_TRACE=true
export AGK_TRACE_EXPORTER=file  # Default if not specified
```

**Storage Location:** `.agk/runs/<run-id>/trace.jsonl`

The file exporter automatically creates a run directory structure and generates a unique run ID.

### OTLP Exporter

Send traces to OpenTelemetry collectors (Jaeger, Tempo, etc.):

```bash
export AGK_TRACE=true
export AGK_TRACE_EXPORTER=otlp
export AGK_TRACE_ENDPOINT=http://localhost:4318
```

**Default Endpoint:** `http://localhost:4318` (if not specified)

---

## Integration with Jaeger

### Run Jaeger All-in-One

```bash
docker run -d --name jaeger \
  -e COLLECTOR_OTLP_ENABLED=true \
  -p 16686:16686 \
  -p 4318:4318 \
  jaegertracing/all-in-one:latest
```

### Configure Agent

```bash
export AGK_TRACE=true
export AGK_TRACE_EXPORTER=otlp
export AGK_TRACE_ENDPOINT=http://localhost:4318
```

```go
agent, err := v1beta.NewChatAgent("Assistant",
    v1beta.WithLLM("openai", "gpt-4"),
)
```

### View Traces

Open browser: `http://localhost:16686`

Select service: `agenticgokit` (or your custom service name)

---

## Integration with Tempo

### Run Grafana Tempo

```yaml
# docker-compose.yml
version: "3"
services:
  tempo:
    image: grafana/tempo:latest
    command: [ "-config.file=/etc/tempo.yaml" ]
    volumes:
      - ./tempo.yaml:/etc/tempo.yaml
    ports:
      - "4318:4318"  # OTLP HTTP
      - "3200:3200"  # Tempo UI
```

### Configure Agent

```bash
export AGK_TRACE=true
export AGK_TRACE_EXPORTER=otlp
export AGK_TRACE_ENDPOINT=http://localhost:4318
```

---

## Workflow Observability Examples

### Sequential Workflow

```go
// Enable observability
os.Setenv("AGK_TRACE", "true")

// Create agents
extract, _ := v1beta.NewChatAgent("Extractor", v1beta.WithLLM("openai", "gpt-4"))
transform, _ := v1beta.NewChatAgent("Transformer", v1beta.WithLLM("openai", "gpt-4"))
load, _ := v1beta.NewChatAgent("Loader", v1beta.WithLLM("openai", "gpt-4"))

// Create workflow - observability automatic
workflow, _ := v1beta.NewSequentialWorkflow(&v1beta.WorkflowConfig{
    Mode:    v1beta.Sequential,
    Timeout: 60 * time.Second,
})

workflow.AddStep(v1beta.WorkflowStep{Name: "extract", Agent: extract})
workflow.AddStep(v1beta.WorkflowStep{Name: "transform", Agent: transform})
workflow.AddStep(v1beta.WorkflowStep{Name: "load", Agent: load})

result, _ := workflow.Run(context.Background(), "Process data")
```

**Trace Hierarchy:**
```
agk.workflow.sequential
├── agk.workflow.step: "extract"
│   └── agk.agent.run
│       └── llm.openai.call
├── agk.workflow.step: "transform"
│   └── agk.agent.run
└── agk.workflow.step: "load"
    └── agk.agent.run
```

### Parallel Workflow

```go
os.Setenv("AGK_TRACE", "true")

workflow, _ := v1beta.NewParallelWorkflow(&v1beta.WorkflowConfig{
    Mode:    v1beta.Parallel,
    Timeout: 90 * time.Second,
})

workflow.AddStep(v1beta.WorkflowStep{Name: "sentiment", Agent: sentimentAgent})
workflow.AddStep(v1beta.WorkflowStep{Name: "entities", Agent: entityAgent})

result, _ := workflow.Run(context.Background(), "Analyze text")
```

**Trace Hierarchy:**
```
agk.workflow.parallel
├── agk.workflow.step: "sentiment" (concurrent)
│   └── agk.agent.run
├── agk.workflow.step: "entities" (concurrent)
│   └── agk.agent.run
└── agk.workflow.sync (synchronization overhead)
```

### Subworkflow Composition

```go
os.Setenv("AGK_TRACE", "true")

// Create nested workflow
innerWorkflow, _ := v1beta.NewParallelWorkflow(&v1beta.WorkflowConfig{
    Mode:    v1beta.Parallel,
    Timeout: 60 * time.Second,
})
innerWorkflow.AddStep(v1beta.WorkflowStep{Name: "task1", Agent: agent1})
innerWorkflow.AddStep(v1beta.WorkflowStep{Name: "task2", Agent: agent2})

// Wrap as subworkflow agent
subAgent := v1beta.NewSubWorkflowAgent("parallel_tasks", innerWorkflow)

// Use in main workflow
mainWorkflow, _ := v1beta.NewSequentialWorkflow(&v1beta.WorkflowConfig{
    Mode:    v1beta.Sequential,
    Timeout: 120 * time.Second,
})
mainWorkflow.AddStep(v1beta.WorkflowStep{Name: "nested", Agent: subAgent})

result, _ := mainWorkflow.Run(context.Background(), "Hierarchical workflow")
```

**Trace Hierarchy:**
```
agk.workflow.sequential: "main"
└── agk.workflow.step: "nested"
    └── agk.subworkflow.run: "parallel_tasks"
        ├─ agk.subworkflow.name: "parallel_tasks"
        ├─ agk.subworkflow.path: "main/nested/parallel_tasks"
        ├─ agk.subworkflow.depth: 1
        └── agk.workflow.parallel
            ├── agk.workflow.step: "task1"
            ├── agk.workflow.step: "task2"
            └── agk.workflow.sync
```

---

## Span Attributes Reference

### Agent Spans

| Attribute | Type | Description |
|-----------|------|-------------|
| `agk.agent.name` | string | Agent name |
| `agk.agent.input_bytes` | int | Input size in bytes |
| `agk.agent.output_bytes` | int | Output size in bytes |
| `agk.agent.success` | bool | Execution success status |
| `agk.agent.total_tokens` | int | Total LLM tokens used |

### LLM Spans

| Attribute | Type | Description |
|-----------|------|-------------|
| `llm.provider` | string | Provider name (openai, anthropic, etc.) |
| `llm.model` | string | Model identifier |
| `llm.temperature` | float | Temperature setting |
| `llm.max_tokens` | int | Max tokens setting |
| `llm.prompt_tokens` | int | Input tokens consumed |
| `llm.completion_tokens` | int | Output tokens generated |
| `llm.total_tokens` | int | Total tokens (prompt + completion) |
| `llm.latency_ms` | int64 | LLM call latency |
| `llm.success` | bool | Call success status |

### Tool Spans

| Attribute | Type | Description |
|-----------|------|-------------|
| `agk.tool.name` | string | Tool name |
| `agk.tool.input_bytes` | int | Input size |
| `agk.tool.output_bytes` | int | Output size |
| `agk.tool.latency_ms` | int64 | Execution latency |
| `agk.tool.success` | bool | Success status |

### MCP Tool Spans

| Attribute | Type | Description |
|-----------|------|-------------|
| `agk.tool.name` | string | MCP tool name |
| `agk.mcp.server` | string | MCP server name |
| `agk.mcp.tool.input_bytes` | int | Input size |
| `agk.mcp.tool.output_bytes` | int | Output size |
| `agk.mcp.tool.latency_ms` | int64 | Execution latency |
| `agk.mcp.tool.content_count` | int | Number of content items |
| `agk.mcp.tool.success` | bool | Success status |

### Workflow Spans

| Attribute | Type | Description |
|-----------|------|-------------|
| `agk.workflow.id` | string | Workflow execution ID |
| `agk.workflow.mode` | string | Execution mode (sequential, parallel, dag, loop) |
| `agk.workflow.step_count` | int | Total steps in workflow |
| `agk.workflow.completed_steps` | int | Successfully completed steps |
| `agk.workflow.timeout_seconds` | int | Configured timeout |
| `agk.workflow.success` | bool | Overall success status |
| `agk.workflow.tokens_used` | int | Total tokens across all steps |

### Workflow Step Spans

| Attribute | Type | Description |
|-----------|------|-------------|
| `agk.workflow.step_name` | string | Step identifier |
| `agk.workflow.step_index` | int | Step position (0-indexed) |
| `agk.workflow.input_bytes` | int | Step input size |
| `agk.workflow.output_bytes` | int | Step output size |
| `agk.workflow.latency_ms` | int64 | Step execution time |
| `agk.workflow.success` | bool | Step success status |

### Subworkflow Spans

| Attribute | Type | Description |
|-----------|------|-------------|
| `agk.subworkflow.name` | string | Subworkflow name |
| `agk.subworkflow.path` | string | Hierarchical path (e.g., "main/analysis") |
| `agk.subworkflow.depth` | int | Nesting depth (0 = root) |
| `agk.subworkflow.workflow_mode` | string | Wrapped workflow type |
| `agk.subworkflow.input_bytes` | int | Input size |
| `agk.subworkflow.output_bytes` | int | Output size |
| `agk.subworkflow.latency_ms` | int64 | Execution latency |
| `agk.subworkflow.total_tokens` | int | LLM tokens consumed |
| `agk.subworkflow.steps_executed` | int | Number of workflow steps |
| `agk.subworkflow.success` | bool | Success status |

---

## CLI Commands

### List Traces

```bash
# List all runs
agk trace list

# Filter by status
agk trace list --status success
agk trace list --status failed

# Limit results
agk trace list --limit 20
```

### Show Trace

```bash
# Show full trace tree
agk trace show <run-id>

# Show with all attributes
agk trace show <run-id> --verbose

# Filter by span type
agk trace show <run-id> --filter workflow
```

**Example Output:**
```
Run ID: abc123def456
Status: Success
Duration: 2.5s
Total Spans: 12

Trace Tree:
║ agk.workflow.sequential (2500ms)
║   ├── agk.workflow.step: "extract" (800ms)
║   │   ├─ agk.workflow.step_name: extract
║   │   ├─ agk.workflow.step_index: 0
║   │   ├─ agk.workflow.input_bytes: 256
║   │   └── agk.agent.run (780ms)
║   │       └── llm.openai.call (750ms)
║   │           ├─ llm.model: gpt-4
║   │           ├─ llm.total_tokens: 120
║   │           └─ llm.latency_ms: 750
```

### View in Browser

```bash
# Open trace in Jaeger UI (requires Jaeger running)
agk trace view <run-id>
```

### Export Trace

```bash
# Export to JSON
agk trace export <run-id> --format json > trace.json

# Export to Jaeger format
agk trace export <run-id> --format jaeger > trace-jaeger.json

# Export to OTLP format
agk trace export <run-id> --format otlp > trace-otlp.json
```

---

## Performance Considerations

### Overhead

Observability has minimal overhead when properly configured:

- **Tracing disabled**: 0% overhead
- **Tracing enabled (console)**: < 1% overhead
- **Tracing enabled (file)**: < 2% overhead
- **Tracing enabled (OTLP)**: < 3% overhead

### Sampling

Control sampling rate to reduce overhead in production:

```bash
# Sample 10% of traces
export AGK_TRACE_SAMPLE=0.1
```

### Production Best Practices

1. **Use OTLP exporter** for centralized collection
2. **Set appropriate sample rate** (0.1 for high-volume apps)
3. **Use batch exporters** (default in OTLP)
4. **Monitor exporter health** (check OTLP endpoint availability)
5. **Set resource limits** (max spans per trace, max attributes per span)

---

## Troubleshooting

### No Traces Appearing

**Problem:** Traces not visible in collector

**Solutions:**
1. Check observability is enabled: `export AGK_TRACE=true`
2. Verify exporter endpoint: Check `AGK_TRACE_ENDPOINT`
3. Confirm collector is running: `curl http://localhost:4318`
4. Check sample rate: Ensure not sampling out all traces

### Incomplete Spans

**Problem:** Missing child spans or attributes

**Solutions:**
1. Ensure context is properly propagated
2. Check span is ended: `defer span.End()`
3. Verify error handling doesn't skip span completion

### High Overhead

**Problem:** Performance degradation with tracing enabled

**Solutions:**
1. Reduce sample rate: `export AGK_TRACE_SAMPLE=0.1`
2. Use batch exporters (default for OTLP)
3. Disable console exporter in production
4. Check collector is not bottleneck

### Workflow Spans Missing

**Problem:** Workflow or subworkflow spans not appearing

**Solutions:**
1. Update to latest version (v0.6.0+)
2. Ensure workflows created after observability enabled
3. Check CLI filter includes "workflow" keyword: `agk trace show <run-id> --filter workflow`

---

## Next Steps

- **[Configuration Guide](./configuration.md)** - Detailed configuration options
- **[Workflows Guide](./workflows.md)** - Multi-agent workflow patterns
- **[Performance Guide](./performance.md)** - Optimization and tuning
- **[Troubleshooting](./troubleshooting.md)** - Common issues and solutions
- **[Examples](./examples/observability-basic.md)** - Complete code examples
