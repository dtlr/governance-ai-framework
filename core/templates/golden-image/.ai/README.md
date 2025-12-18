# AI Artifacts

This directory contains AI-related artifacts for this repository.

## Structure

```
.ai/
├── ledger/           # Operations tracking
│   ├── LEDGER.md     # Implementation operations
│   ├── PLANNING.md   # Feature planning sessions
│   └── EFFICIENCY.md # Cost tracking
├── inference/        # Repo-specific rules only
│   └── README.md     # Points to global rules
├── bundles/          # Repo-specific bundles (if any)
└── _scratch/         # Ephemeral working files (gitignored)
```

## Global Resources (in Submodule)

All global documentation and rules are in `.governance/ai/`:

| Resource | Path |
|----------|------|
| **Inference Rules** | `.governance/ai/core/inference-rules/` |
| **Bundles** | `.governance/ai/core/templates/golden-image/.ai/bundles/` |
| **Automation** | `.governance/ai/core/automation/` |
| **Documentation** | `.governance/ai/README.md` |

## Quick Commands

```bash
# Align repo to governance
.governance/ai/core/automation/align-repo.sh

# Plan a feature
.governance/ai/core/automation/plan-feature.sh --request "Add X"

# Research a question
.governance/ai/core/automation/plan-feature.sh --research --question "Best way to..."
```

## Local vs Global

| Type | Location | When to Use |
|------|----------|-------------|
| **Global** | `.governance/ai/core/inference-rules/` | Universal rules (all repos) |
| **Local** | `.ai/inference/` | Repo-specific rules only |

If you find yourself adding a rule that would benefit all repos, contribute it to the submodule.
