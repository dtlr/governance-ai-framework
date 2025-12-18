# Directory Contract (Human + AI Reference)

This file is a high-signal overview of what each directory should contain and how files should be managed.

## Authoritative Inference Rules

Global rules (in governance submodule):
- `.governance/ai/core/inference-rules/directory-contract.md` - A/B/C file classification
- `.governance/ai/core/inference-rules/file-lifecycle.md` - Create/update/delete workflow
- `.governance/ai/core/inference-rules/repo-router.md` - Directory→purpose mapping
- `.governance/ai/core/inference-rules/submodule-management.md` - Governance updates

Instance-specific rules (in this repo):
- `.ai/inference/<topic>/INFERENCE.md` - Repo-specific learnings

## Rule Precedence

1. Global rules (submodule) - Apply to all repos
2. Instance rules (`.ai/inference/`) - Override/extend for this repo only
