# PDR: Repository Alignment to Governance Golden Image

## Problem Statement

Repositories without standardized AI governance structures suffer from:
- **Context explosion**: AI loads 60k+ tokens upfront → slow responses
- **Inconsistency**: Each repo has different rules → unpredictable behavior
- **No recovery**: AI gets interrupted → all progress lost
- **Token waste**: 7.7M+ token burns across long sessions

## Solution

Automatically align any repository to the governance golden-image structure by:
1. Detecting current repo shape and project type
2. Comparing against golden-image template
3. Generating missing files from templates
4. Establishing consistent AI operating constraints

## Success Criteria

| Metric | Before | After |
|--------|--------|-------|
| Context load | 60k+ tokens | <15k tokens |
| File classification | None | A/B/C enforced |
| Recovery capability | None | LEDGER.md + batching |
| Token efficiency | Ad-hoc | Lazy loading + tiers |

## Required Components

### Governance Layer (`.governance/`)
- `manifest.json` - Discovery contract
- `README.md` - Governance overview
- `DIRECTORY_CONTRACT.md` - A/B/C classification

### Local Overrides (`.governance-local/`)
- `overrides.yaml` - Repo-specific configuration

### AI Artifacts (`.ai/`)
- `ledger/LEDGER.md` - Operations audit trail
- `ledger/EFFICIENCY.md` - Cost tracking
- `_scratch/` - Ephemeral working directory
- `inference/` - Repo-specific inference rules
- `bundles/` - Repeatable operation packs

### Documentation (`docs/_shared/`)
- `router.md` - Intent→load routing map
- Project-specific docs as needed

## Non-Goals

- Modifying existing business logic
- Changing project dependencies
- Restructuring existing code

## Risks

| Risk | Mitigation |
|------|------------|
| Overwrites existing files | Check existence before create |
| Wrong project type detected | Manual override in overrides.yaml |
| Missing context for repo | Prompt user for clarification |

## Implementation Plan

See `prompts/` directory for atomic execution steps.
