# Inference: Repo Router (docs/_shared/router.md)

## Intent
Governance submodule docs are portable and only reference paths relative to `governance_root`.
Each repo has a unique structure outside `.governance/`, so a repo-owned router is required.

## Required file
- `docs/_shared/router.md`

## Decision Rules
1) Before non-trivial work, load:
   - governance router (`.governance/ai/00_INDEX/...`)
   - repo router (`docs/_shared/router.md`)
2) If the target area is not covered, update the router first (single-file, minimal diff).
3) Keep router schema-like: tables + triggers, avoid prose sprawl.
4) Keep “do not scan” directories current.

## Output Contracts
- Router updates are logged in `.ai/ledger/LEDGER.md`.
