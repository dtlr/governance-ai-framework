# Prompt 06b: Prioritize and Present Tasks for Review

## Context
Tasks have been decomposed. Now prioritize and present for user review.

## Input
Read:
- `.ai/_scratch/feature-*/tasks.json`
- `.ai/_scratch/feature-*/FEATURE.md`
- `.ai/_scratch/feature-*/validation.md`

## Task
Assign priorities and create a user-reviewable breakdown.

## Priority Criteria

| Priority | Criteria | Action |
|----------|----------|--------|
| **P0 - Critical** | Blocks other work, security-critical, breaks without it | Must do now |
| **P1 - High** | Core functionality, significant value | Should do now |
| **P2 - Medium** | Enhancements, nice-to-have | Can defer |
| **P3 - Low** | Polish, optimization | Defer to backlog |

## Instructions

### 1. For each task, evaluate:

- **Business value**: How much does this matter to users?
- **Technical risk**: What breaks if we skip this?
- **Dependencies**: Do other tasks need this first?
- **Effort**: Is the value worth the effort?

### 2. Assign priority with reasoning:

```json
{
  "id": "01",
  "name": "implement-core-resource",
  "priority": "P0",
  "priority_reason": "Core functionality - feature doesn't work without this",
  "defer_safe": false,
  "defer_impact": "Feature will not function"
}
```

### 3. Output to `.ai/_scratch/feature-*/REVIEW.md`:

```markdown
# Task Review & Prioritization

## Summary

| Priority | Count | Estimated Effort |
|----------|-------|------------------|
| P0 - Critical | X | Xh |
| P1 - High | X | Xh |
| P2 - Medium | X | Xh |
| P3 - Low | X | Xh |
| **Total** | X | Xh |

## Recommended Execution Plan

### Phase 1: Critical (Must Do)

#### Task 01: [name]
- **Priority**: P0 - Critical
- **Reason**: [why critical]
- **Effort**: ~Xh
- **Files**: `path/to/file.tf`
- **Risk if skipped**: ⛔ Feature non-functional

#### Task 02: [name]
...

### Phase 2: High Priority (Should Do)

#### Task 03: [name]
- **Priority**: P1 - High
- **Reason**: [why high]
- **Effort**: ~Xh
- **Files**: `path/to/file.tf`
- **Risk if skipped**: ⚠️ Degraded functionality

### Phase 3: Can Defer (Nice to Have)

#### Task 04: [name]
- **Priority**: P2 - Medium
- **Reason**: [why medium]
- **Effort**: ~Xh
- **Files**: `path/to/file.tf`
- **Risk if skipped**: 📝 Minor impact
- **Defer to**: GitHub Issue (backlog)

#### Task 05: [name]
- **Priority**: P3 - Low
- **Reason**: [why low]
- **Effort**: ~Xh
- **Risk if skipped**: ✅ No immediate impact
- **Defer to**: GitHub Issue (future enhancement)

## User Decision Required

Please review and decide:

- [ ] **Execute all** - Run all tasks now
- [ ] **Execute P0+P1 only** - Defer P2/P3 to GitHub issue
- [ ] **Execute P0 only** - Defer P1/P2/P3 to GitHub issue
- [ ] **Custom selection** - Specify which tasks to run

### Deferred Work

Tasks not executed will be:
1. Bundled with relevant context (PDR.md, research/)
2. Created as GitHub issue with label `ai-deferred`
3. Linked to original feature in issue body
4. Tagged with priority for future triage

## Approval

To proceed, user must specify:
```
EXECUTE: [all | p0-p1 | p0 | custom:01,02,03]
```
```

### 4. Update tasks.json with priorities:

Add `priority`, `priority_reason`, `defer_safe`, `defer_impact` to each task.

## Completion
Say "Task review ready. User approval required before execution."
Output the REVIEW.md summary to console.
