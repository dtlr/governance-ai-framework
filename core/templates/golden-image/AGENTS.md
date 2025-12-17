# AGENTS (Root Operator Guide)

This is the long-form guide for AI operators.

## Entry Contract
- `.governance/manifest.json` defines Tier 1 context.
- `.governance/ai/00_INDEX/README.md` defines routing triggers and tiering.
- `.governance-local/overrides.yaml` defines repo-specific toggles.

## AI Artifact Lifecycle
- Durable AI artifacts: `.ai/`
- Ephemeral artifacts: `.ai/_scratch/` (safe to delete; never commit)
- Provenance: `.ai/ledger/LEDGER.md`
- Executable plans: `.ai/bundles/<bundle>/RUN.md`

## How to run the default governance bundle
Open and run:
- `.ai/bundles/ai-file-governance-v1/RUN.md`

## Directory Contract Inference
- `.ai/inference/directory-contract/INFERENCE.md`
- `.ai/inference/file-lifecycle/INFERENCE.md`

## Repo Router
- `docs/_shared/router.md` maps this repo’s unique layout for AI routing.
- Inference: `.ai/inference/repo-router/INFERENCE.md`
