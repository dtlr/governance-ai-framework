# AI Ledger (Append-Only)

Every AI execution must append an entry here.

## Entry Template

```markdown
## YYYY-MM-DD — <Short Title>

**Agent:** <Model/Tool>
**Bundle:** <.ai/bundles/...> (if applicable)
**Intent:** <what was attempted>
**Result:** SUCCESS | PARTIAL | FAILED

### Usage Metrics (REQUIRED)
- **Tokens:** Input: X, Output: Y, Total: Z
- **Cost:** $X.XX (calculation: input×rate + output×rate)
- **Context:** Xk/200k tokens (peak context window usage)

### Artifacts
| Path | Type | Class (A/B/C) | Notes |
|------|------|---------------|-------|
| ...  | ...  | ...           | ...   |

### Cleanup
- Deleted: <list>
- Preserved: <list + why>

### Notes / Open Questions
- ...
```

## Cost Reference (2025-01)

| Model | Input (per 1M) | Output (per 1M) |
|-------|----------------|-----------------|
| Claude Opus 4.5 | $15.00 | $75.00 |
| Claude Sonnet 4 | $3.00 | $15.00 |
| Claude Haiku | $0.25 | $1.25 |

**Calculation:** `(input_tokens × input_rate / 1M) + (output_tokens × output_rate / 1M)`

## Why Track Usage?

1. **Cost visibility** - Know actual spend per operation
2. **Efficiency tracking** - Identify expensive operations for optimization
3. **Budget planning** - Historical data for forecasting
4. **Model selection** - Compare cost/quality tradeoffs

---

<!-- Entries below this line -->
