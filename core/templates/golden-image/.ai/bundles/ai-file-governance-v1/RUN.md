# RUN: AI File Governance Bundle (Golden Image)

You are operating in a repository that uses a governance submodule at `.governance/ai`.

## Load First
- `.governance/manifest.json`
- `.governance/ai/00_INDEX/README.md`
- `.governance/ai/core/CONFIG.md` (if present)
- `.governance/ai/core/DOC_TYPES.md` (if present)
- `.governance-local/overrides.yaml`
- `CLAUDE.md`

## Mission
1) Evaluate the repo against the governance + AI artifact lifecycle contract.
2) Implement missing wrapper files and `.ai/` scaffolding in small batches.
3) Update `.ai/ledger/LEDGER.md`.

## Rules
- Classify files A/B/C.
- Put ephemeral outputs in `.ai/_scratch/`.
- Max 20 new files per batch (or overrides.yaml value if present).

## Execute Prompts
Run prompts in `prompts/` in order.

## End
Print a File Ledger Summary and confirm scratch cleanup.
