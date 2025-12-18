# Instance-Level Inference

This directory is for **repo-specific learnings** that AI discovers while working in THIS repository.

## What Goes Here

- Patterns unique to this codebase
- Learnings about this repo's conventions
- Repo-specific decision rules

## What Does NOT Go Here

Generic inference rules belong in the governance submodule. See the full index at:
`.governance/ai/core/inference-rules/README.md`

Global rules include:
- `lazy-loading.md` - Load context on-demand
- `three-tier-system.md` - Progressive context tiers
- `directory-contract.md` - A/B/C file classification
- `file-lifecycle.md` - Create/update/delete workflow
- `repo-router.md` - Directory→purpose mapping
- `submodule-management.md` - Governance version updates

## Usage

When AI learns something specific to this repo, create a subdirectory with an `INFERENCE.md`:

```
.ai/inference/
├── README.md           ← This file
└── <topic>/
    └── INFERENCE.md    ← Repo-specific learning
```

## Rule Precedence

1. **Global rules** (`.governance/ai/core/inference-rules/`) - Apply everywhere
2. **Instance rules** (this directory) - Override/extend for THIS repo only
