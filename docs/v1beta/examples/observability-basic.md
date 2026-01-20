# Observability Example

This example demonstrates how to enable observability for agents and workflows with distributed tracing and structured logging.

---

## Basic Agent with Observability

```go
package main

import (
    "context"
    "log"
    "os"
    
    "github.com/agenticgokit/agenticgokit/v1beta"
)

func main() {
    // Set API key
    os.Setenv("OPENAI_API_KEY", "your-api-key-here")
    
    // Enable observability via environment variable
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

### What Gets Traced

**Console output** (when using default console exporter):

```json
{
  "Name": "agk.agent.run",
  "SpanContext": {
    "TraceID": "abc123...",
    "SpanID": "def456..."
  },
  "Attributes": [
    {"Key": "agk.agent.name", "Value": "Assistant"},
    {"Key": "agk.agent.input_bytes", "Value": 12},
    {"Key": "agk.agent.output_bytes", "Value": 45},
    {"Key": "agk.agent.success", "Value": true},
    {"Key": "agk.agent.total_tokens", "Value": 28}
  ],
  "Children": [
    {
      "Name": "llm.openai.call",
      "Attributes": [
        {"Key": "llm.provider", "Value": "openai"},
        {"Key": "llm.model", "Value": "gpt-4"},
        {"Key": "llm.total_tokens", "Value": 28},
        {"Key": "llm.latency_ms", "Value": 450}
      ]
    }
  ]
}
```

---

## Agent with Tools and Observability

```go
package main

import (
    "context"
    "fmt"
    "log"
    "os"
    
    "github.com/agenticgokit/agenticgokit/v1beta"
)

func calculator(args map[string]interface{}) (string, error) {
    // Tool execution automatically traced
    op := args["operation"].(string)
    a := args["a"].(float64)
    b := args["b"].(float64)
    
    var result float64
    switch op {
    case "add":
        result = a + b
    case "multiply":
        result = a * b
    default:
        return "", fmt.Errorf("unknown operation: %s", op)
    }
    
    return fmt.Sprintf("%.2f", result), nil
}

func main() {
    os.Setenv("OPENAI_API_KEY", "your-api-key-here")
    
    // Enable observability with console exporter
    os.Setenv("AGK_TRACE", "true")
    os.Setenv("AGK_TRACE_EXPORTER", "console")
    
    // Create agent with tools - observability automatic
    agent, err := v1beta.NewChatAgent("Calculator",
        v1beta.WithLLM("openai", "gpt-4"),
        v1beta.WithTools([]v1beta.Tool{
            {
                Name:        "calculator",
                Description: "Perform arithmetic operations",
                Func:        calculator,
            },
        }),
    )
    if err != nil {
        log.Fatal(err)
    }
    
    result, err := agent.Run(context.Background(), "Calculate 123 * 456")
    if err != nil {
        log.Fatal(err)
    }
    
    log.Printf("Result: %s", result.Content)
}
```

### Trace Hierarchy

```
agk.agent.run (1200ms)
├── llm.openai.call (800ms)
│   ├─ llm.model: gpt-4
│   └─ llm.total_tokens: 85
└── agk.tool.call: "calculator" (150ms)
    ├─ agk.tool.input_bytes: 48
    ├─ agk.tool.output_bytes: 16
    └─ agk.tool.success: true
```

---

## Multi-Agent Workflow with Observability

```go
package main

import (
    "context"
    "log"
    "os"
    "time"
    
    "github.com/agenticgokit/agenticgokit/v1beta"
)

func main() {
    os.Setenv("OPENAI_API_KEY", "your-api-key-here")
    
    // Enable observability for all agents
    os.Setenv("AGK_TRACE", "true")
    
    // Create agents - observability automatic
    researcher, _ := v1beta.NewChatAgent("Researcher",
        v1beta.WithLLM("openai", "gpt-4"),
    )
    
    analyzer, _ := v1beta.NewChatAgent("Analyzer",
        v1beta.WithLLM("openai", "gpt-4"),
    )
    
    writer, _ := v1beta.NewChatAgent("Writer",
        v1beta.WithLLM("openai", "gpt-4"),
    )
    
    // Create workflow - observability automatic
    workflow, err := v1beta.NewSequentialWorkflow(&v1beta.WorkflowConfig{
        Mode:    v1beta.Sequential,
        Timeout: 180 * time.Second,
    })
    if err != nil {
        log.Fatal(err)
    }
    
    workflow.AddStep(v1beta.WorkflowStep{Name: "research", Agent: researcher})
    workflow.AddStep(v1beta.WorkflowStep{Name: "analyze", Agent: analyzer})
    workflow.AddStep(v1beta.WorkflowStep{Name: "write", Agent: writer})
    
    // Execute - complete workflow trace
    result, err := workflow.Run(context.Background(), "Research AI trends in 2026")
    if err != nil {
        log.Fatal(err)
    }
    
    log.Printf("Final output: %s", result.FinalOutput)
}
```

### Workflow Trace Hierarchy

```
agk.workflow.sequential (2500ms)
├─ agk.workflow.mode: sequential
├─ agk.workflow.step_count: 3
├─ agk.workflow.completed_steps: 3
├─ agk.workflow.success: true
└─ Steps:
   ├── agk.workflow.step: "research" (800ms)
   │   ├─ agk.workflow.step_name: research
   │   ├─ agk.workflow.step_index: 0
   │   └── agk.agent.run (780ms)
   │       └── llm.openai.call (750ms)
   │
   ├── agk.workflow.step: "analyze" (900ms)
   │   └── agk.agent.run (880ms)
   │       └── llm.openai.call (850ms)
   │
   └── agk.workflow.step: "write" (800ms)
       └── agk.agent.run (780ms)
           └── llm.openai.call (750ms)
```

---

## Using OTLP Exporter with Jaeger

### Step 1: Run Jaeger

```bash
docker run -d --name jaeger \
  -e COLLECTOR_OTLP_ENABLED=true \
  -p 16686:16686 \
  -p 4318:4318 \
  jaegertracing/all-in-one:latest
```

### Step 2: Configure Agent

```go
package main

import (
    "context"
    "log"
    "os"
    
    "github.com/agenticgokit/agenticgokit/v1beta"
)

func main() {
    os.Setenv("OPENAI_API_KEY", "your-api-key-here")
    
    // Enable observability with OTLP exporter
    os.Setenv("AGK_TRACE", "true")
    os.Setenv("AGK_TRACE_EXPORTER", "otlp")
    os.Setenv("AGK_TRACE_ENDPOINT", "http://localhost:4318")
    
    // Create agent - observability automatic
    agent, err := v1beta.NewChatAgent("Assistant",
        v1beta.WithLLM("openai", "gpt-4"),
    )
    if err != nil {
        log.Fatal(err)
    }
    
    // Run agent
    result, err := agent.Run(context.Background(), "Explain quantum computing")
    if err != nil {
        log.Fatal(err)
    }
    
    log.Printf("Result: %s", result.Content)
}
```

### Step 3: View in Jaeger UI

Open browser: `http://localhost:16686`

1. Select service: `agenticgokit`
2. Click **Find Traces**
3. Click on a trace to see the full hierarchy

---

## Subworkflow Observability

```go
package main

import (
    "context"
    "log"
    "os"
    "time"
    
    "github.com/agenticgokit/agenticgokit/v1beta"
)

func main() {
    os.Setenv("OPENAI_API_KEY", "your-api-key-here")
    
    // Enable observability
    os.Setenv("AGK_TRACE", "true")
    
    // Create validation subworkflow (parallel)
    formatValidator, _ := v1beta.NewChatAgent("FormatValidator",
        v1beta.WithLLM("openai", "gpt-4"),
    )
    
    integrityValidator, _ := v1beta.NewChatAgent("IntegrityValidator",
        v1beta.WithLLM("openai", "gpt-4"),
    )
    
    validationWorkflow, _ := v1beta.NewParallelWorkflow(&v1beta.WorkflowConfig{
        Mode:    v1beta.Parallel,
        Timeout: 30 * time.Second,
    })
    
    validationWorkflow.AddStep(v1beta.WorkflowStep{Name: "format", Agent: formatValidator})
    validationWorkflow.AddStep(v1beta.WorkflowStep{Name: "integrity", Agent: integrityValidator})
    
    // Wrap as subworkflow agent
    validationAsAgent := v1beta.NewSubWorkflowAgent("validation", validationWorkflow)
    
    // Create main workflow
    processAgent, _ := v1beta.NewChatAgent("Processor",
        v1beta.WithLLM("openai", "gpt-4"),
    )
    
    mainWorkflow, _ := v1beta.NewSequentialWorkflow(&v1beta.WorkflowConfig{
        Mode:    v1beta.Sequential,
        Timeout: 120 * time.Second,
    })
    
    mainWorkflow.AddStep(v1beta.WorkflowStep{Name: "validate", Agent: validationAsAgent})
    mainWorkflow.AddStep(v1beta.WorkflowStep{Name: "process", Agent: processAgent})
    
    // Execute - hierarchical trace with depth tracking
    result, err := mainWorkflow.Run(context.Background(), "Process data")
    if err != nil {
        log.Fatal(err)
    }
    
    log.Printf("Result: %s", result.FinalOutput)
}
```

### Subworkflow Trace Hierarchy

```
agk.workflow.sequential: "main" (1500ms)
├── agk.workflow.step: "validate" (800ms)
│   └── agk.subworkflow.run: "validation" (780ms)
│       ├─ agk.subworkflow.name: validation
│       ├─ agk.subworkflow.path: main/validate/validation
│       ├─ agk.subworkflow.depth: 1
│       ├─ agk.subworkflow.workflow_mode: parallel
│       └── agk.workflow.parallel (760ms)
│           ├── agk.workflow.step: "format" (500ms)
│           │   └── agk.agent.run
│           ├── agk.workflow.step: "integrity" (450ms)
│           │   └── agk.agent.run
│           └── agk.workflow.sync (0ms)
│
└── agk.workflow.step: "process" (700ms)
    └── agk.agent.run (680ms)
```

---

## Environment Variable Configuration

Instead of programmatic configuration, use environment variables:

```bash
# Enable tracing
export AGK_TRACE=true

# Set exporter (console, file, or otlp)
export AGK_TRACE_EXPORTER=otlp

# Set OTLP endpoint
export AGK_TRACE_ENDPOINT=http://localhost:4318

# Set file path (for file exporter)
export AGK_TRACE_FILEPATH=.agk/runs/trace.jsonl

# Set sample rate (0.0 to 1.0)
export AGK_TRACE_SAMPLE=1.0
```

```go
package main

import (
    "context"
    "log"
    "os"
    
    "github.com/agenticgokit/agenticgokit/v1beta"
)

func main() {
    os.Setenv("OPENAI_API_KEY", "your-api-key-here")
    
    // Observability configured via environment variables
    agent, err := v1beta.NewChatAgent("Assistant",
        v1beta.WithLLM("openai", "gpt-4"),
    )
    if err != nil {
        log.Fatal(err)
    }
    
    result, err := agent.Run(context.Background(), "Hello!")
    if err != nil {
        log.Fatal(err)
    }
    
    log.Printf("Result: %s", result.Content)
}
```

---

## CLI Commands

After running agents with observability enabled, use CLI commands to view traces:

```bash
# List all runs
agk trace list

# Show specific trace
agk trace show <run-id>

# Show with verbose output (all attributes)
agk trace show <run-id> --verbose

# Filter by workflow spans
agk trace show <run-id> --filter workflow

# View in Jaeger UI (requires Jaeger running)
agk trace view <run-id>

# Export to JSON
agk trace export <run-id> --format json > trace.json
```

### Example CLI Output

```bash
$ agk trace show abc123

Run ID: abc123def456
Status: Success
Duration: 2.5s
Total Spans: 12

Trace Tree:
║ agk.workflow.sequential (2500ms)
║   ├── agk.workflow.step: "research" (800ms)
║   │   ├─ agk.workflow.step_name: research
║   │   ├─ agk.workflow.input_bytes: 256
║   │   └── agk.agent.run (780ms)
║   │       └── llm.openai.call (750ms)
║   │           ├─ llm.model: gpt-4
║   │           ├─ llm.total_tokens: 120
║   │           └─ llm.latency_ms: 750
```

---

## Performance Considerations

### Overhead

- **Tracing disabled**: 0% overhead
- **Console exporter**: < 1% overhead
- **File exporter**: < 2% overhead
- **OTLP exporter**: < 3% overhead

### Sampling for Production

Reduce overhead in high-volume production systems:

Use environment variable:

```bash
export AGK_TRACE_SAMPLE=0.1
```

---

## Related Documentation

- **[Observability Guide](../observability.md)** - Complete observability documentation
- **[Configuration Guide](../configuration.md)** - All configuration options
- **[Workflows Guide](../workflows.md)** - Multi-agent workflows
- **[Tool Integration](../tool-integration.md)** - Tool and MCP integration

---

**Ready for more?** Check out the [Observability Guide](../observability.md) for complete documentation →
