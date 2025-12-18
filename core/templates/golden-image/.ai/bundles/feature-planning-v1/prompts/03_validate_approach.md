# Prompt 03: Validate Approach and Push Back

## Context
Research complete. Now critically evaluate the request and push back if needed.

## Input
Read:
- `.ai/_scratch/request-analysis.md`
- `.ai/_scratch/research/codebase.md`
- `.ai/_scratch/research/docs.md`

## Task
Act as a **skeptical senior architect** who:
1. Questions assumptions
2. Identifies risks
3. Proposes alternatives
4. PUSHES BACK on bad ideas
5. Gives honest assessment

## Instructions

### 1. Risk Assessment

Evaluate each risk category:

| Category | Questions to Ask |
|----------|------------------|
| **Security** | Does this expose secrets? Create attack surface? Violate least privilege? |
| **Reliability** | Single points of failure? Recovery plan? Degradation behavior? |
| **Cost** | Unexpected charges? Scaling costs? Resource waste? |
| **Complexity** | Is this over-engineered? Simpler alternative? Maintenance burden? |
| **Dependencies** | Tight coupling? Version lock-in? Vendor lock-in? |
| **Operations** | Monitoring gaps? Debugging difficulty? Deployment risk? |

### 2. Push Back Checklist

STOP and WARN if any of these are true:

- [ ] **Anti-pattern detected**: Request follows known bad practice
- [ ] **Scope creep**: Request is much larger than it appears
- [ ] **Missing prerequisites**: Other changes needed first
- [ ] **Breaking change**: Will disrupt existing functionality
- [ ] **Security risk**: Introduces vulnerabilities
- [ ] **Cost explosion**: Could cause unexpected charges
- [ ] **Simpler alternative exists**: Over-engineering detected

### 3. Recommendations

For each concern, provide:
- **BLOCK**: Do not proceed (explain why)
- **WARN**: Proceed with caution (mitigation required)
- **NOTE**: Acknowledge but proceed (document the tradeoff)
- **APPROVE**: No concerns

### 4. Output to `.ai/_scratch/validation.md`:

```markdown
# Approach Validation

## Executive Summary
**Recommendation**: [APPROVE / APPROVE WITH CHANGES / BLOCK]
**Confidence**: [HIGH / MEDIUM / LOW]
**Risk Level**: [LOW / MEDIUM / HIGH / CRITICAL]

## Push Back Items

### 🛑 BLOCKED: [Title] (if any)
**Reason**: [Why this cannot proceed]
**Required Action**: [What must change]

### ⚠️ WARNING: [Title]
**Risk**: [What could go wrong]
**Mitigation**: [Required safeguard]
**Owner**: [Who needs to address]

### 📝 NOTE: [Title]
**Tradeoff**: [What we're accepting]
**Rationale**: [Why it's acceptable]

## Risk Matrix

| Risk | Likelihood | Impact | Mitigation | Status |
|------|------------|--------|------------|--------|
| [risk] | [H/M/L] | [H/M/L] | [action] | [MITIGATED/ACCEPTED/OPEN] |

## Alternative Approaches Considered

### Recommended: [Approach Name]
**Why**: [Reasoning]
**Tradeoffs**: [What we give up]

### Rejected: [Approach Name]
**Why not**: [Reasoning]

## Prerequisites Identified
- [ ] [Prerequisite 1]
- [ ] [Prerequisite 2]

## Questions for User
1. [Question requiring user input]
2. [Question requiring user input]

## Approval Conditions
If proceeding, these conditions MUST be met:
1. [Condition 1]
2. [Condition 2]

## Final Verdict
[Detailed reasoning for the recommendation]
```

## Completion
If BLOCKED: Output concerns and STOP. Do not proceed to generation.
If APPROVED (with or without changes): Say "Validation complete. Proceeding to spec generation."
