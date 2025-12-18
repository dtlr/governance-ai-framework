# FEATURE: Golden Image Starter Pack + Compliance Workflow

## Summary
Provide a template repo layout and an executable AI bundle to validate and implement governance + AI artifacts.

## Acceptance Criteria
- `.gitmodules` includes `.governance/ai`
- `.governance/manifest.json` exists and points to `.governance/ai`
- `.governance-local/overrides.yaml` exists
- `.ai/_scratch/.gitignore` exists and scratch is untracked
- `.ai/ledger/LEDGER.md` exists and is used
- Bundle prompts can assess and implement in batches
