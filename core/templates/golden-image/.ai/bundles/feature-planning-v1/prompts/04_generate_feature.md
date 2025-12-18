# Prompt 04: Generate FEATURE.md

## Context
Approach validated. Now generate the formal feature specification.

## Input
Read:
- `.ai/_scratch/request-analysis.md`
- `.ai/_scratch/research/codebase.md`
- `.ai/_scratch/research/docs.md`
- `.ai/_scratch/validation.md`

## Task
Generate a comprehensive FEATURE.md that can stand alone as the feature specification.

## Instructions

1. **Determine feature name** (slug format):
   - User request: "Add Redis caching" → `redis-cache`
   - Create output directory: `.ai/_scratch/feature-<name>/`

2. **Write FEATURE.md** following this structure:

```markdown
# FEATURE: [Feature Title]

## Overview

[2-3 sentence description of what this feature does and why it matters]

## User Story

As a [role],
I want [capability],
So that [benefit].

## Acceptance Criteria

### Must Have (P0)
- [ ] [Criterion 1 - specific, testable]
- [ ] [Criterion 2 - specific, testable]

### Should Have (P1)
- [ ] [Criterion 3]
- [ ] [Criterion 4]

### Nice to Have (P2)
- [ ] [Criterion 5]

## Scope

### In Scope
- [What IS included]

### Out of Scope
- [What is explicitly NOT included]
- [Future considerations]

## Technical Approach

### Architecture
[High-level description of how this will be implemented]

### Components Affected
| Component | Change Type | Description |
|-----------|-------------|-------------|
| [module/file] | [NEW/MODIFY/DELETE] | [what changes] |

### Dependencies
- **Requires**: [what must exist first]
- **Provides**: [what this enables]

## Validation

### How to Test
1. [Test step 1]
2. [Test step 2]

### Success Metrics
- [Metric 1]: [target value]
- [Metric 2]: [target value]

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| [risk] | [H/M/L] | [action] |

## Timeline Estimate

| Phase | Effort | Notes |
|-------|--------|-------|
| Implementation | [X hours/days] | [assumptions] |
| Testing | [X hours/days] | |
| Documentation | [X hours/days] | |

## References

- [Link to relevant docs]
- [Link to related issues]
```

3. **Output to**: `.ai/_scratch/feature-<name>/FEATURE.md`

## Quality Checklist
- [ ] Acceptance criteria are specific and testable
- [ ] Scope is clearly defined (in AND out)
- [ ] Technical approach aligns with validation.md recommendations
- [ ] Risks from validation.md are included
- [ ] No ambiguous language ("should", "might", "could consider")

## Completion
Say "FEATURE.md generated at .ai/_scratch/feature-<name>/FEATURE.md"
