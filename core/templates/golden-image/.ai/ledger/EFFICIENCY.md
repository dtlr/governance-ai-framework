# Prompt Efficiency Tracking

Track prompt-to-cost patterns to optimize AI usage over time.

## Operation Types

| Type | Description | Expected Cost Range |
|------|-------------|---------------------|
| `explore` | Searching, reading, understanding codebase | $0.50 - $2.00 |
| `create` | Writing new files, features | $2.00 - $8.00 |
| `refactor` | Restructuring existing code | $1.50 - $6.00 |
| `debug` | Troubleshooting, fixing bugs | $1.00 - $5.00 |
| `review` | Code review, analysis | $0.50 - $3.00 |
| `config` | Configuration, setup | $1.00 - $4.00 |
| `docs` | Documentation updates | $0.50 - $2.00 |

## Rolling Summary (Update Weekly)

### Cost by Operation Type

| Type | Count | Avg Tokens | Avg Cost | Trend | Notes |
|------|-------|------------|----------|-------|-------|
| explore | - | - | - | - | |
| create | - | - | - | - | |
| refactor | - | - | - | - | |
| debug | - | - | - | - | |
| review | - | - | - | - | |
| config | - | - | - | - | |
| docs | - | - | - | - | |

**Trend Legend:** ↓ improving, → stable, ↑ needs attention

### Monthly Totals

| Month | Operations | Total Tokens | Total Cost | Avg/Op |
|-------|------------|--------------|------------|--------|
| 2025-01 | - | - | - | - |

---

## High-Cost Operations (Review These)

Operations exceeding expected range for their type:

| Date | Operation | Type | Cost | Expected | Why Expensive | Optimization |
|------|-----------|------|------|----------|---------------|--------------|
| | | | | | | |

---

## Optimization Recommendations

### Model Selection
- **Haiku ($0.25/$1.25 per 1M)**: Exploration, simple edits, formatting
- **Sonnet ($3/$15 per 1M)**: Standard development, code review
- **Opus ($15/$75 per 1M)**: Complex architecture, critical decisions

### Prompt Efficiency Patterns

1. **Batch similar operations** - Create multiple related files in one session
2. **Use subagents for parallel work** - Exploration agents are cheaper
3. **Load context lazily** - Don't read files until needed
4. **Be specific in requests** - Vague prompts cause exploration loops
5. **Provide examples** - Reduces back-and-forth clarification

### Context Management
- **Start lean** - Begin with Tier 1 context only
- **Discard when switching** - Don't carry stale context
- **Use pointers** - Reference docs instead of quoting them

---

## Feedback Loop

After each session, AI should:

1. **Log metrics** to LEDGER.md (Tokens, Cost, Context)
2. **Categorize operation** type in ledger entry
3. **Compare to averages** in this file
4. **Flag if expensive** - Add to High-Cost Operations table
5. **Suggest optimization** - Note what could be done differently

### Self-Assessment Questions

After expensive operations, ask:
- Could this have used a cheaper model?
- Was unnecessary context loaded?
- Could work have been parallelized?
- Was the prompt specific enough?
- Could caching have helped?

---

## Updating This File

**Weekly:** Update Rolling Summary with data from LEDGER.md
**After expensive ops:** Add to High-Cost Operations table
**Monthly:** Archive to `EFFICIENCY-YYYY-MM.md` and reset tables
