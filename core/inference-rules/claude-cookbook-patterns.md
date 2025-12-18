# Claude Cookbook Patterns - Efficiency & Accuracy Reference

**Pointer guide to Anthropic's official cookbook patterns for improving AI efficiency and accuracy.**

Source: https://github.com/anthropics/anthropic-cookbook

---

## Quick Reference Matrix

| Goal | Pattern | Cookbook Location | Impact |
|------|---------|-------------------|--------|
| **Reduce costs 90%** | Prompt Caching | `misc/prompt_caching.ipynb` | Cache static context |
| **Reduce latency 2x** | Prompt Caching | `misc/prompt_caching.ipynb` | Skip re-processing |
| **Save 58% tokens** | Context Compaction | `tool_use/automatic-context-compaction.ipynb` | Summarize history |
| **Improve accuracy** | Extended Thinking | `extended_thinking/` | Step-by-step reasoning |
| **Structured output** | JSON Mode | `misc/how_to_enable_json_mode.ipynb` | Reliable parsing |
| **Type safety** | Pydantic Tools | `tool_use/tool_use_with_pydantic.ipynb` | Validated inputs |
| **Parallel speedup** | Parallelization | `patterns/agents/basic_workflows.ipynb` | Concurrent calls |
| **Task routing** | Routing Pattern | `patterns/agents/basic_workflows.ipynb` | Specialized prompts |
| **Complex tasks** | Orchestrator-Workers | `patterns/agents/orchestrator_workers.ipynb` | Divide and conquer |
| **Iterative refinement** | Evaluator-Optimizer | `patterns/agents/evaluator_optimizer.ipynb` | Feedback loops |

---

## 1. Efficiency Patterns

### 1.1 Prompt Caching

**Purpose:** Reduce latency by >2x and costs up to 90% for repetitive tasks with static context.

**How it works:**
```python
# Add cache_control to content blocks
messages = [{
    "role": "user",
    "content": [
        {
            "type": "text",
            "text": large_static_document,
            "cache_control": {"type": "ephemeral"}
        },
        {
            "type": "text",
            "text": "Query about the document"
        }
    ]
}]
```

**When to use:**
- Large reference documents (governance rules, codebases, manuals)
- Multi-turn conversations with stable system prompts
- Repeated queries against same context

**Key metrics to track:**
- `cache_creation_input_tokens`: First call (cache miss)
- `cache_read_input_tokens`: Subsequent calls (cache hit)

**Reference:** `misc/prompt_caching.ipynb`

---

### 1.2 Context Compaction

**Purpose:** Reduce token usage by 58%+ in long-running workflows by summarizing history.

**How it works:**
```python
# SDK built-in for tool workflows
runner = client.beta.messages.tool_runner(
    model=MODEL,
    tools=tools,
    messages=messages,
    compaction_control={
        "enabled": True,
        "context_token_threshold": 5000,  # Trigger threshold
    }
)
```

**When to use:**
- Sequential entity processing (batch operations)
- Workflows with natural checkpoints
- Tasks where detailed audit trail isn't required

**When NOT to use:**
- Tasks requiring complete history
- Workflows completing within 50-100k tokens

**Reference:** `tool_use/automatic-context-compaction.ipynb`

---

### 1.3 Parallelization

**Purpose:** Reduce latency by processing independent subtasks concurrently.

**How it works:**
```python
from concurrent.futures import ThreadPoolExecutor

def parallel(prompt: str, inputs: list[str], n_workers: int = 3):
    with ThreadPoolExecutor(max_workers=n_workers) as executor:
        futures = [executor.submit(llm_call, f"{prompt}\nInput: {x}")
                   for x in inputs]
        return [f.result() for f in futures]
```

**When to use:**
- Same prompt applied to multiple inputs
- Independent analysis tasks
- Latency-sensitive operations

**Reference:** `patterns/agents/basic_workflows.ipynb`

---

## 2. Accuracy Patterns

### 2.1 Extended Thinking

**Purpose:** Improve accuracy by allowing step-by-step reasoning before responding.

**When to use:**
- Complex multi-step problems
- Mathematical or logical analysis
- Code debugging and optimization
- Tasks requiring error-catching

**Key benefit:** Claude can work through problems internally, catching errors before the final response.

**Reference:** `extended_thinking/extended_thinking.ipynb`

---

### 2.2 Evaluator-Optimizer Loop

**Purpose:** Iteratively refine outputs through evaluation and feedback cycles.

**How it works:**
```python
def optimize_loop(task, max_iterations=5):
    result = generate(task)

    for i in range(max_iterations):
        evaluation = evaluate(result)
        if evaluation.status == "PASS":
            return result
        result = generate(task, feedback=evaluation.feedback)

    return result
```

**When to use:**
- Tasks with clear evaluation criteria
- Code generation (correctness, style, performance)
- Content that benefits from refinement

**Reference:** `patterns/agents/evaluator_optimizer.ipynb`

---

### 2.3 Structured Output (JSON Mode)

**Purpose:** Ensure consistent, parseable output format.

**Techniques:**

1. **Response Prefilling** (most reliable):
```python
messages = [
    {"role": "user", "content": "Extract data as JSON..."},
    {"role": "assistant", "content": "{"}  # Pre-fill opening brace
]
```

2. **XML Tag Wrapping** (for multiple objects):
```python
# Instruct Claude to wrap JSON in tags
prompt = "Output each item in <item></item> tags as JSON"
# Extract with regex
results = re.findall(r"<item>(.+?)</item>", response, re.DOTALL)
```

3. **Tool Use** (built-in validation):
```python
# Define tool with JSON schema
# Claude must conform to schema to call tool
```

**Reference:** `misc/how_to_enable_json_mode.ipynb`

---

### 2.4 Pydantic Tool Definitions

**Purpose:** Type-safe tool inputs with automatic validation.

**How it works:**
```python
from pydantic import BaseModel, Field, EmailStr

class ToolInput(BaseModel):
    name: str
    email: EmailStr
    priority: int = Field(ge=1, le=5, default=3)
    tags: list[str] | None = None

def process_tool_call(tool_input: dict):
    validated = ToolInput(**tool_input)  # Raises if invalid
    # Proceed with validated data
```

**Benefits:**
- Type checking at runtime
- Constraint validation (min/max, format)
- Clear error messages for invalid inputs

**Reference:** `tool_use/tool_use_with_pydantic.ipynb`

---

## 3. Architecture Patterns

### 3.1 Prompt Chaining

**Purpose:** Decompose complex tasks into sequential steps.

**How it works:**
```python
def chain(input: str, prompts: list[str]) -> str:
    result = input
    for prompt in prompts:
        result = llm_call(f"{prompt}\nInput: {result}")
    return result
```

**When to use:**
- Data transformation pipelines
- Multi-stage analysis
- Tasks where later steps depend on earlier results

**Example:** Raw data → Extract → Normalize → Format → Validate

**Reference:** `patterns/agents/basic_workflows.ipynb`

---

### 3.2 Routing

**Purpose:** Direct requests to specialized prompts based on classification.

**How it works:**
```python
def route(input: str, routes: dict[str, str]) -> str:
    # Step 1: Classify input
    route_key = classify(input, list(routes.keys()))

    # Step 2: Use specialized prompt
    return llm_call(f"{routes[route_key]}\nInput: {input}")
```

**When to use:**
- Customer support (billing vs technical vs account)
- Domain-specific expertise
- Optimizing prompts for input types

**Reference:** `patterns/agents/basic_workflows.ipynb`

---

### 3.3 Orchestrator-Workers

**Purpose:** Coordinate specialized workers for complex tasks.

**How it works:**
1. Orchestrator analyzes task and determines subtasks
2. Workers receive original context + specific instructions
3. Orchestrator combines worker outputs

```python
class Orchestrator:
    def process(self, task):
        # Analyze and plan
        subtasks = self.plan(task)

        # Delegate to workers
        results = {}
        for subtask in subtasks:
            results[subtask.type] = self.worker(task, subtask)

        # Combine results
        return self.synthesize(results)
```

**When to use:**
- Multi-perspective analysis
- Tasks requiring different expertise areas
- Complex content generation

**Reference:** `patterns/agents/orchestrator_workers.ipynb`

---

## 4. Integration Patterns

### 4.1 RAG (Retrieval Augmented Generation)

**Purpose:** Enhance responses with external knowledge.

**Components:**
- Embedding model for semantic search
- Vector database for storage
- Retrieval pipeline for context injection

**When to use:**
- Domain-specific knowledge requirements
- Up-to-date information needs
- Large knowledge bases

**Reference:** `capabilities/retrieval_augmented_generation/guide.ipynb`

---

### 4.2 Tool Search with Embeddings

**Purpose:** Select appropriate tools from large tool sets using semantic search.

**When to use:**
- Many available tools (50+)
- Dynamic tool selection
- Context-aware tool routing

**Reference:** `tool_use/tool_search_with_embeddings.ipynb`

---

### 4.3 MCP Server Integration

**Purpose:** Connect Claude to external systems via Model Context Protocol.

**Available integrations:**
- Git MCP Server (13+ repository tools)
- GitHub MCP Server (100+ platform tools)
- Custom MCP servers for enterprise systems

**When to use:**
- CI/CD pipeline monitoring
- Repository analysis
- External system automation

**Reference:** `claude_agent_sdk/observability_agent/`

---

## 5. Evaluation Patterns

### 5.1 Three Grading Approaches

| Method | Speed | Reliability | Cost | When to Use |
|--------|-------|-------------|------|-------------|
| **Code-based** | Fast | Highest | Free | Definitive answers, regex matching |
| **Model-based** | Medium | High | API cost | Subjective quality, rubric-based |
| **Human** | Slow | Varies | Expensive | Complex judgment, validation |

**Key insight:** Grading costs recur perpetually. Design for automation.

**Reference:** `misc/building_evals.ipynb`

---

### 5.2 Evaluation Design

**Best practices:**
- Structure questions for automated grading
- Represent real-world distributions
- Validate model-based grading through sampling
- Prioritize volume over perfection

**Reference:** `misc/building_evals.ipynb`

---

## 6. Agent SDK Patterns

### 6.1 Research Agent (Simple)

**Purpose:** Basic agent loop with web search.

**Key patterns:**
- `query()` and async iteration
- WebSearch tool integration
- Conversation context management

**Reference:** `claude_agent_sdk/research_agent/`

---

### 6.2 Chief of Staff Agent (Complex)

**Purpose:** Production-ready multi-agent orchestration.

**Key patterns:**
- Memory persistence via CLAUDE.md
- Plan mode for strategy without execution
- Custom slash commands
- Hooks for compliance/audit
- Subagent orchestration

**Reference:** `claude_agent_sdk/chief_of_staff_agent/`

---

### 6.3 Observability Agent (Enterprise)

**Purpose:** DevOps monitoring with external system integration.

**Key patterns:**
- Git/GitHub MCP server integration
- Real-time CI/CD monitoring
- Automated incident response

**Reference:** `claude_agent_sdk/observability_agent/`

---

## Application to Governance Framework

### High-Value Patterns for This Repo

| Pattern | Application | Priority |
|---------|-------------|----------|
| **Prompt Caching** | Cache governance rules in system prompt | HIGH |
| **Context Compaction** | Long terraform planning sessions | MEDIUM |
| **Routing** | Direct to module-specific context | HIGH |
| **Structured Output** | STATE_CACHE generation, plan parsing | HIGH |
| **Evaluator-Optimizer** | Code review, documentation quality | MEDIUM |

### Implementation Recommendations

1. **Prompt Caching for Governance**
   - Cache `.governance/ai/core/**` content
   - Invalidate on version bump only
   - Expected savings: 50-70% on repeated sessions

2. **Routing for Module Context**
   - Classify user intent → route to module
   - Avoids loading all module context upfront
   - Matches existing three-tier system

3. **Structured Output for State**
   - Use JSON mode for STATE_CACHE generation
   - Pydantic validation for resource schemas
   - Reliable parsing for automation

---

## Related Documentation

- Official Cookbooks: https://github.com/anthropics/anthropic-cookbook
- API Documentation: https://docs.anthropic.com
- Building Effective Agents: https://anthropic.com/research/building-effective-agents
- Prompt Engineering Guide: https://docs.anthropic.com/claude/docs/prompt-engineering
