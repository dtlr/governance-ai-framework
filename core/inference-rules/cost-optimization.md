# Inference: Cost Optimization & Efficiency Tracking

## Intent

Establish feedback loop between prompts and costs to continuously improve AI efficiency. Track patterns, identify expensive operations, and suggest optimizations.

---

## Mandatory Tracking (Every Session)

### Ledger Entry Requirements

Every `.ai/ledger/LEDGER.md` entry MUST include:

```markdown
- **Operation Type:** [explore | create | refactor | debug | review | config | docs]
- **Tokens:** Input: X, Output: Y, Total: Z
- **Cost:** $X.XX (calculation)
- **Context:** Xk/200k tokens
```

### Post-Session Analysis

After completing work, AI MUST:

1. **Compare cost to expected range** (see EFFICIENCY.md)
2. **If over budget:** Add to High-Cost Operations table with explanation
3. **Suggest optimization** for future similar operations

---

## Cost Expectations by Operation Type

| Type | Input Tokens | Output Tokens | Expected Cost (Opus) |
|------|--------------|---------------|----------------------|
| explore | 20-40k | 5-15k | $0.50 - $2.00 |
| create | 40-80k | 20-50k | $2.00 - $8.00 |
| refactor | 50-100k | 15-40k | $1.50 - $6.00 |
| debug | 30-70k | 10-30k | $1.00 - $5.00 |
| review | 20-50k | 5-20k | $0.50 - $3.00 |
| config | 30-60k | 15-30k | $1.00 - $4.00 |
| docs | 15-40k | 10-20k | $0.50 - $2.00 |

---

## Model Selection Rules

### Use Haiku ($0.25/$1.25 per 1M) for:
- File exploration and search
- Simple formatting tasks
- Boilerplate generation
- Quick lookups

### Use Sonnet ($3/$15 per 1M) for:
- Standard code changes
- Code review
- Documentation
- Most daily development

### Use Opus ($15/$75 per 1M) for:
- Complex architecture decisions
- Multi-file refactoring
- Critical production changes
- Novel problem solving

---

## Efficiency Patterns

### 1. Context Loading

```
❌ EXPENSIVE: Load everything, then work
   Cost: High input tokens, much wasted

✅ EFFICIENT: Load progressively as needed
   Cost: Minimal input, targeted context
```

**Rule:** Start with Tier 1, load Tier 2/3 only when needed.

### 2. Parallel vs Sequential

```
❌ EXPENSIVE: Create files one at a time, waiting between
   Cost: Multiple round-trips, repeated context

✅ EFFICIENT: Batch related file operations
   Cost: Single context load, parallel creates
```

**Rule:** Use Task tool with multiple subagents for independent work.

### 3. Prompt Specificity

```
❌ EXPENSIVE: "Fix the auth system"
   Cost: Exploration loops, clarification rounds

✅ EFFICIENT: "Add JWT validation to /api/auth endpoint using existing authMiddleware"
   Cost: Direct implementation, minimal exploration
```

**Rule:** Include: what, where, how, constraints.

### 4. Example-Driven Prompts

```
❌ EXPENSIVE: "Create a config file for linting"
   Cost: Research, multiple attempts

✅ EFFICIENT: "Create eslint.config.js like the one in package-a"
   Cost: Pattern matching, single attempt
```

**Rule:** Reference existing patterns when available.

### 5. Context Recycling

```
❌ EXPENSIVE: Keep all context when switching tasks
   Cost: Irrelevant tokens consuming budget

✅ EFFICIENT: Explicitly discard and reload
   Cost: Fresh, relevant context only
```

**Rule:** State "Discarding X context, loading Y" when switching.

---

## Red Flags (Investigate These)

| Pattern | Likely Cause | Fix |
|---------|--------------|-----|
| >$10 for explore | Loading too much context | Use subagents |
| >$15 for create | Iteration/clarification loops | Be more specific |
| Context >150k | Not discarding stale context | Explicit discard |
| Same file read 3+ times | Poor context management | Read once, reference |
| Output > Input | Verbose generation | Ask for concise output |

---

## Weekly Review Protocol

1. **Extract from LEDGER.md:**
   - Count operations by type
   - Calculate averages
   - Identify outliers

2. **Update EFFICIENCY.md:**
   - Rolling Summary table
   - High-Cost Operations table
   - Trend indicators

3. **Identify patterns:**
   - Which operation types are expensive?
   - What optimizations are working?
   - What new patterns emerged?

4. **Adjust expectations:**
   - Update expected ranges if consistently different
   - Note successful optimizations

---

## Integration Points

- **LEDGER.md**: Raw operation data with costs
- **EFFICIENCY.md**: Aggregated analysis and trends
- **file-lifecycle.md**: Mandatory tracking requirements
- **lazy-loading.md**: Context loading patterns
- **three-tier-system.md**: Context tier budgets

---

## Failure Conditions

- ❌ Ledger entry without Tokens/Cost/Context
- ❌ Operation type not categorized
- ❌ High-cost operation without explanation
- ❌ Weekly summary not updated
