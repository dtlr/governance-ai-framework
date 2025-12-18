# Inference: Cost-Optimal Routing

## Intent

Define a tiered routing strategy that minimizes AI costs while maximizing effectiveness. The cheapest AI is the AI you don't call.

---

## The Routing Ladder (Lowest Cost First)

### Tier 0 — No Model Call

**Use deterministic tools first.** Many tasks don't need AI at all.

| Tool | Use For | Example |
|------|---------|---------|
| `ripgrep`/`grep` | Pattern search | Find all API endpoints |
| `glob` | File discovery | Find all *.tf files |
| `git diff` | Change analysis | What changed since last commit? |
| `tree`/`ls` | Structure understanding | Directory layout |
| `jq`/`yq` | JSON/YAML parsing | Extract specific field |
| Schema validators | Format checking | Is this valid JSON? |
| Linters | Code checking | Syntax errors, style issues |

**Rule:** If Tier 0 can answer the question, stop. Don't escalate.

**Examples (Tier 0 sufficient):**
- "What files are in src/?" → `tree src/`
- "Find usages of PaymentService" → `grep -r "PaymentService"`
- "Is this valid JSON?" → `jq . file.json`
- "What changed?" → `git diff`

### Tier 1 — Cheap Model, Tiny Context

**Use smaller/cheaper models for classification and extraction.**

| Task | Why Cheap Works |
|------|-----------------|
| File classification | "Is this test file relevant?" |
| Entity extraction | "Extract all function names" |
| Ambiguity detection | "Are requirements clear?" |
| Summarization | "Summarize this error log" |
| Routing decisions | "Which module owns this?" |

**Model selection:**
- Claude Haiku ($0.25/$1.25 per 1M)
- Or equivalent cheap tier in your stack

**Rule:** Inputs should be pointers, not full documents (see Pointer Packs below).

### Tier 2 — Mid Model for Structured Planning

**Use mid-tier models for validated intermediate artifacts.**

| Task | Output |
|------|--------|
| Task decomposition | `tasks.yaml` |
| Dependency mapping | `dependencies.dot` |
| Plan generation | `plan.md` |
| Code review | `review.md` |

**Model selection:**
- Claude Sonnet ($3/$15 per 1M)
- Or equivalent mid tier

**Rule:** Only invoke after Tier 1 has produced a compact, validated intermediate artifact.

### Tier 3 — Expensive Model for Hard Reasoning

**Reserve expensive models for genuinely hard problems.**

| Task | Why Expensive Needed |
|------|---------------------|
| Dependency conflicts | Multiple constraints to resolve |
| Architecture decisions | Non-obvious tradeoffs |
| Safety-critical changes | High consequence requires deep analysis |
| Novel problem solving | No existing pattern applies |
| Multi-constraint optimization | Pareto frontier exploration |

**Model selection:**
- Claude Opus ($15/$75 per 1M)
- Or equivalent premium tier

**Rule:** Expensive models should NEVER ingest raw documents or whole repos. They receive curated context only.

---

## Pointer Packs (Not Context Stuffing)

The most cost-effective context is **file pointers + line ranges + query results**, not full files.

### Pointer Pack Structure

```yaml
context_bundle:
  repo_rev: "git:3a91c2f"
  files:
    - path: "docs/requirements.md"
      excerpt:
        start_line: 120
        end_line: 240
    - path: "src/auth/login.ts"
      excerpt:
        start_line: 1
        end_line: 50
  grep_hits:
    - query: "PaymentWebhook"
      results:
        - path: "src/webhooks/adyen.ts"
          lines: [33, 88]
        - path: "src/webhooks/stripe.ts"
          lines: [45]
  summary:
    total_lines: 170
    files_referenced: 3
```

### What Gets Sent to Model

Only:
- Relevant excerpts (not full files)
- Grep hit lines (not all occurrences)
- Minimal surrounding context (±20-50 lines)

### Token Impact

| Approach | Tokens | Cost (Opus) |
|----------|--------|-------------|
| Full repo dump | 500k+ | $50+ |
| Full file stuffing | 100k | $10 |
| Pointer pack | 10-20k | $1-2 |

---

## Content-Hash Caching

### Principle

Use content hashes to avoid re-processing unchanged content.

```
chunk_hash = sha256(file_path + start_line + end_line + content)
cache_key = chunk_hash + prompt_hash + model_id
```

### What to Cache

| Artifact | Key | Value |
|----------|-----|-------|
| File summaries | `sha256(file_content) + "summary"` | Extracted summary |
| Extraction results | `sha256(chunk) + schema_hash` | Structured output |
| Review results | `sha256(diff) + "review"` | Review comments |

### Cache Invalidation

- File changed → chunk hash changes → cache miss (re-process)
- Schema changed → schema hash changes → cache miss
- Model changed → model_id changes → cache miss

### Impact

For repeated operations (daily reviews, CI checks):
- First run: Full cost
- Subsequent runs: Cache hits for unchanged content → Near-zero cost

---

## Confidence Gates

### Tier 1 Output Contract

Cheap tier models should output confidence metadata:

```yaml
result:
  answer: "This file handles user authentication"
  confidence: 0.85
  risk: "low"
  need_more_context: false
  reasoning: "File path and imports indicate auth responsibility"
```

### Escalation Rules

| Condition | Action |
|-----------|--------|
| `confidence < 0.75` | Escalate to higher tier |
| `risk == "high"` | Escalate to higher tier |
| `need_more_context == true` | Fetch more context, retry same tier |
| Schema validation fails | Retry with correction prompt |

### Anti-Pattern

```
❌ EXPENSIVE: Use Opus for every question
   Result: $50/session, slow responses

✅ EFFICIENT: Route through tiers with confidence gates
   Result: $2-5/session, same quality for most tasks
```

---

## Output Token Minimization

Output tokens often cost more than input (Opus: $75 vs $15 per 1M).

### Enforcement Patterns

| Pattern | Implementation |
|---------|----------------|
| Strict schemas | Force JSON/YAML output |
| No prose preambles | System prompt: "Output only the requested format" |
| Bounded fields | Max 5 bullets, max 200 chars per field |
| References over repetition | "See pointer P12" instead of copying |
| Structured responses | Tables over paragraphs |

### Prompt Template

```
Output format: JSON only. No explanation.
Schema: {schema}
Constraints:
- max_array_length: 10
- max_string_length: 200
- no_prose: true
```

---

## Practical Router Implementation

### For Claude Code Sessions

```
User Request
    │
    ├─ Can Tier 0 answer? (grep, glob, git, validators)
    │   └─ YES → Execute tool, return result, STOP
    │
    ├─ Is this classification/extraction?
    │   └─ YES → Use Task tool with model=haiku
    │
    ├─ Is this planning/structured output?
    │   └─ YES → Use current model (usually Sonnet)
    │
    └─ Is this hard reasoning/architecture?
        └─ YES → Recommend Opus if not already using
```

### For Custom Pipelines

```yaml
router_policy:
  tier_0:
    tools: [ripgrep, glob, git, jq, validators]
    timeout_ms: 5000

  tier_1:
    model: "claude-haiku"
    max_input_tokens: 20000
    max_output_tokens: 2000
    confidence_threshold: 0.75
    tasks: [classify, extract, summarize, route]

  tier_2:
    model: "claude-sonnet"
    max_input_tokens: 50000
    max_output_tokens: 5000
    tasks: [plan, review, generate, refactor]

  tier_3:
    model: "claude-opus"
    max_input_tokens: 100000
    max_output_tokens: 10000
    tasks: [architecture, conflict_resolution, safety_critical]
    require_escalation_reason: true

  escalation_rules:
    - condition: "confidence < 0.75"
      action: "escalate_tier"
    - condition: "risk == 'high'"
      action: "escalate_to_tier_3"
    - condition: "validation_failed"
      action: "retry_with_correction"
```

---

## Integration with Existing Patterns

### Relationship to Three-Tier Context System

| Context Tier | Routing Tier | Notes |
|--------------|--------------|-------|
| Tier 1 (Root CLAUDE.md) | Usually Tier 1-2 models | Simple navigation |
| Tier 2 (Module context) | Tier 2 models | Structured work |
| Tier 3 (Deep dive) | Tier 2-3 models | Complex analysis |

### Relationship to Lazy Loading

Lazy loading determines **what** to load.
Cost-optimal routing determines **how** to process it.

```
Lazy Loading: "Load module CLAUDE.md when working on module"
Cost Routing: "Use Tier 1 model to classify, Tier 2 to plan, Tier 3 only if complex"
```

---

## Metrics to Track

### Per-Session

| Metric | Target |
|--------|--------|
| Tier 0 resolution rate | >30% of queries |
| Tier 3 usage rate | <10% of queries |
| Average cost per query | <$0.50 |
| Cache hit rate | >50% for repeated workflows |

### Weekly Review

1. What queries went to Tier 3 that could have been Tier 1-2?
2. What queries failed at Tier 1 that should have been routed higher?
3. Are confidence gates calibrated correctly?
4. What's the cache hit rate for repeated operations?

---

## Failure Conditions

- ❌ Using Tier 3 model for simple classification
- ❌ Stuffing full files instead of pointer packs
- ❌ No confidence gates (always escalating)
- ❌ No caching for repeated operations
- ❌ Verbose output when structured would suffice
- ❌ Skipping Tier 0 (calling AI when tools suffice)
