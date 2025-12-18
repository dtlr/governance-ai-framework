# Prompt 05: Generate PDR.md

## Context
FEATURE.md generated. Now generate the Product Design Record.

## Input
Read:
- `.ai/_scratch/feature-<name>/FEATURE.md`
- `.ai/_scratch/validation.md`
- `.ai/_scratch/research/docs.md`

## Task
Generate a PDR.md that documents the technical design decisions.

## Instructions

Write PDR.md following this structure:

```markdown
# PDR: [Feature Title]

**Status**: DRAFT | APPROVED | IMPLEMENTED
**Author**: [AI-assisted]
**Date**: [YYYY-MM-DD]
**Feature**: [link to FEATURE.md]

## Problem Statement

### Current State
[Description of how things work now]

### Pain Points
1. [Pain point 1]
2. [Pain point 2]

### Impact
[Who is affected and how]

## Proposed Solution

### Summary
[2-3 sentence description of the solution]

### Technical Design

#### Component: [Component 1]
**Purpose**: [what it does]
**Implementation**:
```hcl
# Pseudo-code or structure
resource "type" "name" {
  # key configuration
}
```

#### Component: [Component 2]
...

### Data Flow
```
[User/Service] → [Component A] → [Component B] → [Output]
```

### State Changes
| Resource | Before | After |
|----------|--------|-------|
| [resource] | [state] | [state] |

## Alternatives Considered

### Alternative 1: [Name]
**Description**: [How it would work]
**Pros**:
- [Pro 1]
**Cons**:
- [Con 1]
**Verdict**: REJECTED - [reason]

### Alternative 2: [Name]
...

## Security Considerations

### Authentication/Authorization
- [How access is controlled]

### Data Protection
- [How sensitive data is handled]

### Audit Trail
- [What is logged]

## Operational Considerations

### Deployment
- **Strategy**: [Blue-green, rolling, etc.]
- **Rollback**: [How to revert]

### Monitoring
- **Metrics**: [What to track]
- **Alerts**: [What triggers alerts]

### Maintenance
- [Ongoing requirements]

## Cost Analysis

| Item | Monthly Cost | Notes |
|------|--------------|-------|
| [resource] | $X | [assumptions] |
| **Total** | $X | |

## Implementation Plan

### Phase 1: [Name]
- [Task 1]
- [Task 2]

### Phase 2: [Name]
- [Task 3]

### Dependencies
```
[Phase 1] → [Phase 2] → [Phase 3]
```

## Testing Strategy

### Unit Tests
- [What to test]

### Integration Tests
- [What to test]

### Manual Validation
- [Steps to verify]

## Success Criteria

| Metric | Current | Target | Measurement |
|--------|---------|--------|-------------|
| [metric] | [value] | [value] | [how to measure] |

## Open Questions

1. [Question 1] - [Who can answer]
2. [Question 2] - [Who can answer]

## References

- [Official doc 1]
- [Related PDR]
- [External resource]

## Appendix

### Glossary
- **Term**: Definition

### Related Documents
- [Document 1]
```

Output to: `.ai/_scratch/feature-<name>/PDR.md`

## Completion
Say "PDR.md generated at .ai/_scratch/feature-<name>/PDR.md"
