# Prompt 00b: Deep Research Execution

## Context
Research plan created. Now execute deep research across sources.

## Input
Read:
- `.ai/_scratch/research-plan.md`
- `.ai/bundles/DOCUMENTATION_STANDARDS.md` (if exists)

## Task
Execute research and produce comprehensive findings.

## Instructions

### 1. For Each Sub-Question

Research systematically:
1. Check official documentation first
2. Look for architecture patterns/examples
3. Find community experiences (gotchas, real-world issues)
4. Note version-specific information
5. Capture cost implications

### 2. Document Findings

For each source consulted:
```markdown
### Source: [Name]
**URL**: [link]
**Relevance**: [HIGH/MEDIUM/LOW]
**Key Findings**:
- [Finding 1]
- [Finding 2]

**Quotes** (if important):
> "[Exact quote from docs]"

**Caveats**:
- [Limitation or outdated info warning]
```

### 3. Build Options Matrix

If comparing approaches:

| Option | Pros | Cons | Cost | Complexity | Best For |
|--------|------|------|------|------------|----------|
| Option A | + Pro 1<br>+ Pro 2 | - Con 1 | $$$ | Medium | [Use case] |
| Option B | + Pro 1 | - Con 1<br>- Con 2 | $$ | Low | [Use case] |

### 4. Risk Analysis

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [Risk 1] | [H/M/L] | [H/M/L] | [How to avoid] |

### 5. Output to `.ai/_scratch/research-findings.md`:

```markdown
# Research Findings

## Executive Summary

[2-3 sentence summary of findings and recommendation]

## Question
[Original question]

## TL;DR Recommendation

**Recommended**: [Option X]
**Why**: [One sentence reason]
**Confidence**: [HIGH/MEDIUM/LOW]

---

## Detailed Analysis

### Option 1: [Name]

**Description**: [What this option is]

**How it works**:
[Technical explanation]

**Pros**:
- ✅ [Pro 1]
- ✅ [Pro 2]

**Cons**:
- ❌ [Con 1]
- ❌ [Con 2]

**Cost Estimate**:
| Component | Monthly | Notes |
|-----------|---------|-------|
| [Item] | $X | [Assumptions] |

**When to use**:
- [Scenario 1]
- [Scenario 2]

**When NOT to use**:
- [Anti-pattern 1]

---

### Option 2: [Name]
[Same structure]

---

## Comparison Matrix

| Criterion | Option 1 | Option 2 | Option 3 |
|-----------|----------|----------|----------|
| Cost | $$$ | $$ | $ |
| Complexity | High | Medium | Low |
| Scalability | Excellent | Good | Limited |
| Vendor Lock-in | Low | Medium | High |
| Community Support | Strong | Moderate | Limited |

## Security Considerations

- [Security point 1]
- [Security point 2]

## Operational Considerations

- [Ops point 1 - monitoring, maintenance, etc.]

## Sources Consulted

| Source | Type | Key Insight |
|--------|------|-------------|
| [Name](URL) | Official | [What we learned] |
| [Name](URL) | Community | [What we learned] |

## Confidence Assessment

| Aspect | Confidence | Why |
|--------|------------|-----|
| Technical accuracy | [H/M/L] | [Reasoning] |
| Cost estimates | [H/M/L] | [Reasoning] |
| Recommendation | [H/M/L] | [Reasoning] |

## Next Steps

If proceeding with recommendation:
1. [Step 1]
2. [Step 2]
3. [Step 3]

## Open Questions

- [Question that couldn't be fully answered]
```

## Completion
Say "Research complete. See .ai/_scratch/research-findings.md"
Output the Executive Summary and TL;DR Recommendation.
