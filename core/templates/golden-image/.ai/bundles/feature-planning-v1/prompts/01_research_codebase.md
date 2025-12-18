# Prompt 01: Research Codebase

## Context
Request has been analyzed. Now research the codebase to understand current state.

## Input
Read:
- `.ai/_scratch/request-analysis.md`
- `docs/_shared/router.md` (if exists)
- Module-specific `CLAUDE.md` files for affected areas

## Task
Investigate the codebase to understand:
1. Current implementation in affected areas
2. Existing patterns and conventions
3. Dependencies and integrations
4. Related code that might be impacted

## Instructions

1. **Load routing information**:
   ```
   Read docs/_shared/router.md to understand repo structure
   ```

2. **For each affected area** from request-analysis.md:
   - Read the module's CLAUDE.md or AGENTS.md
   - Identify key files (main.tf, outputs.tf, etc.)
   - Note existing patterns/conventions
   - Find related/dependent code

3. **Search for existing implementations**:
   - Similar features already implemented?
   - Patterns used elsewhere in the codebase?
   - Utilities or helpers that could be reused?

4. **Identify integration points**:
   - What consumes outputs from affected areas?
   - What provides inputs to affected areas?
   - Cross-module dependencies?

5. **Output to `.ai/_scratch/research/codebase.md`**:

```markdown
# Codebase Research

## Affected Modules Analysis

### [Module Name]
**Location**: [path]
**Purpose**: [description]

#### Current State
- [Key files and their roles]

#### Existing Patterns
- [Pattern 1]: [where used, how it works]
- [Pattern 2]: [where used, how it works]

#### Dependencies
- **Consumes from**: [list]
- **Provides to**: [list]

#### Relevant Code Snippets
```hcl
# [filename]:[line]
[relevant code]
```

## Cross-Module Impact
| Module | Relationship | Impact Risk |
|--------|--------------|-------------|
| [module] | [depends on/provides to] | [HIGH/MEDIUM/LOW] |

## Reusable Components Found
- [Component 1]: [how it could help]

## Technical Constraints Discovered
- [Constraint 1]: [implication]

## Questions for Documentation Research
- [Question about best practices]
- [Question about provider capabilities]
```

## Completion
Say "Codebase research complete. Ready for documentation research."
