# Instance-Level Inference

This directory is for **repo-specific learnings** that AI discovers while working in THIS repository.

## What Goes Here

- Patterns unique to this codebase
- Learnings about this repo's conventions
- Repo-specific decision rules

## What Does NOT Go Here

Generic inference rules belong in the governance submodule:
- `.governance/ai/core/inference-rules/directory-contract.md`
- `.governance/ai/core/inference-rules/file-lifecycle.md`
- `.governance/ai/core/inference-rules/repo-router.md`
- `.governance/ai/core/inference-rules/lazy-loading.md`
- `.governance/ai/core/inference-rules/three-tier-system.md`

## Usage

When AI learns something specific to this repo, create a subdirectory with an `INFERENCE.md`:

```
.ai/inference/
├── README.md           ← This file
└── <topic>/
    └── INFERENCE.md    ← Repo-specific learning
```
