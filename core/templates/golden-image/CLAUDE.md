# CLAUDE (Root Quick Rules)

## Always
- Follow governance routing via `.governance/manifest.json` and `.governance/ai/00_INDEX/README.md`.
- Respect repo-local overrides in `.governance-local/overrides.yaml`.
- Classify every created file as A/B/C:
  - A: repo artifact (ship)
  - B: AI governance artifact (prompts/inference/PDR/feature/eval)
  - C: ephemeral (MUST go in `.ai/_scratch/`)

## Never
- Never commit files under `.ai/_scratch/`.
- Never modify files inside `.governance/ai/` from this repo (submodule-owned).

## Default working style
- Small, reviewable batches
- Prefer edits over new files
- Update `.ai/ledger/LEDGER.md` every run

## Repo Router
- `docs/_shared/router.md` maps this repo's unique layout for AI routing.
- Inference: `.ai/inference/repo-router/INFERENCE.md`

## Config Templates
When setting up project configuration files (eslint, prettier, tsconfig, etc.):
1. Load `core/inference-rules/project-type-detection.md` to detect project type
2. Scan for marker files (package.json, go.mod, *.tf, etc.)
3. Load relevant templates from `docs/_shared/templates/project-configs/`
4. State which configs are relevant and which are skipped (with reasons)

Templates: `docs/_shared/templates/project-configs/` (copied from golden-image)
