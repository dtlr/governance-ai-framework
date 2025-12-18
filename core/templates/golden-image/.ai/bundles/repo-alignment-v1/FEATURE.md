# FEATURE: Repository Alignment to Governance Golden Image

## Overview

Automatically align any repository to the DTLR AI governance structure, establishing:
- Consistent AI operating constraints across all repos
- Token-efficient context loading
- Recoverable operations via ledger tracking
- Standardized documentation routing

## User Story

As a developer onboarding a repository to the governance framework,
I want to run a single alignment process
So that the repository has all required governance infrastructure.

## Acceptance Criteria

- [ ] `manifest.json` created with correct entrypoints
- [ ] `CLAUDE.md` under 2k tokens with pointer-based routing
- [ ] `.ai/` structure with ledger, scratch, inference directories
- [ ] `docs/_shared/router.md` with intent→load mapping
- [ ] All files properly classified as A/B/C
- [ ] `.gitignore` updated for ephemeral paths
- [ ] `LEDGER.md` initialized and records alignment operation

## Non-Goals

- Modifying existing application code
- Changing existing project structure (beyond adding governance)
- Enforcing specific coding standards

## Dependencies

- Governance submodule initialized at `.governance/ai`
- Claude Code or compatible AI assistant
- Write access to repository

## Execution

```bash
# Option 1: Headless execution
./scripts/execute_prompts.sh --dir .governance/ai/core/templates/golden-image/.ai/bundles/repo-alignment-v1/prompts

# Option 2: Interactive
# Run each prompt in prompts/ directory in order
```

## Output Artifacts

| File | Category | Purpose |
|------|----------|---------|
| `.governance/manifest.json` | B | Discovery contract |
| `.governance/DIRECTORY_CONTRACT.md` | B | File classification rules |
| `.governance-local/overrides.yaml` | B | Repo-specific config |
| `CLAUDE.md` | B | AI operating constraints |
| `AGENTS.md` | A | Human-readable guide |
| `.ai/ledger/LEDGER.md` | B | Operations audit |
| `.ai/ledger/EFFICIENCY.md` | B | Cost tracking |
| `.ai/_scratch/.gitignore` | B | Ephemeral file guard |
| `.ai/inference/README.md` | B | Inference rules index |
| `docs/_shared/router.md` | A | Intent routing map |
