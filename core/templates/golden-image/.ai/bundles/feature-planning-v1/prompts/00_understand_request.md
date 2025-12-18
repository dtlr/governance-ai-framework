# Prompt 00: Understand User Request

## Context
You are a Cloud Architect analyzing a user's feature request before implementation.

## Input
Read: `.ai/_scratch/user-request.md`

## Task
Parse the user's request to understand:
1. **What** they want (the feature/change)
2. **Why** they want it (the motivation)
3. **Where** it applies (modules/services affected)
4. **When** it's needed (urgency/priority)
5. **How** they envision it (if specified)

## Instructions

1. **Parse the request** and extract:
   - Core objective (one sentence)
   - Scope (broad/narrow/unclear)
   - Affected areas (modules, services, files)
   - Implied constraints (budget, timeline, compatibility)

2. **Identify ambiguities** that need clarification:
   - Undefined terms
   - Multiple interpretations
   - Missing context
   - Unstated assumptions

3. **Classify the request type**:
   - NEW_FEATURE: Adding new capability
   - ENHANCEMENT: Improving existing feature
   - REFACTOR: Restructuring without behavior change
   - BUGFIX: Correcting existing behavior
   - INFRASTRUCTURE: Platform/tooling change
   - DOCUMENTATION: Docs-only change

4. **Output to `.ai/_scratch/request-analysis.md`**:

```markdown
# Request Analysis

## Original Request
> [quoted user request]

## Parsed Intent
- **Objective**: [one sentence]
- **Type**: [NEW_FEATURE|ENHANCEMENT|REFACTOR|BUGFIX|INFRASTRUCTURE|DOCUMENTATION]
- **Scope**: [BROAD|NARROW|UNCLEAR]

## Affected Areas
| Area | Impact | Confidence |
|------|--------|------------|
| [module/service] | [HIGH/MEDIUM/LOW] | [HIGH/MEDIUM/LOW] |

## Ambiguities Requiring Clarification
1. [Question 1]
2. [Question 2]

## Assumptions Made
- [Assumption 1]
- [Assumption 2]

## Initial Risk Flags
- [Any obvious concerns]

## Ready for Research: [YES/NO]
[If NO, list blocking questions]
```

## Completion
If clarification needed, output questions and STOP.
Otherwise, say "Request understood. Ready for codebase research."
