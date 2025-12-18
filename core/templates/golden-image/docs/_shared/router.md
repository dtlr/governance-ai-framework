# Repo Router (Repository-Specific Context Map)

This file is **repo-owned** and describes the repository’s *unique* directory layout outside `.governance/`.
It is required because the governance submodule can only reference paths **relative to `governance_root`**.

> Update this file whenever top-level directories or ownership boundaries change.

---

## Repository layout map (canonical)

| Path | Owner | What lives here | Notes |
|---|---|---|---|
| docs/ | <TEAM> | Durable repo docs | |
| .ai/ | <TEAM> | AI artifacts (ledger/bundles/scratch) | **Never commit** `.ai/_scratch/` |
| <DIR>/ | <TEAM> | <DESCRIPTION> | |

---

## Document locations (durable)

| Doc type | Canonical path(s) | Notes |
|---|---|---|
| Runbooks | docs/runbooks/ | |
| Policies | docs/policies/ | |
| Architecture | docs/architecture/ | |
| Shared references | docs/_shared/ | Avoid duplication |

---

## Routing triggers (how AI loads context)

- If asked about **governance adoption / rules / manifest**:
  - Load `.governance/manifest.json`, `.governance/README.md`, and governance router docs under `.governance/ai/00_INDEX/…`

- If asked about **AI artifact lifecycle / file sprawl / cleanup**:
  - Load `.ai/README.md`
  - Load `.ai/inference/directory-contract/INFERENCE.md`
  - Load `.ai/inference/file-lifecycle/INFERENCE.md`
  - Load `.ai/inference/repo-router/INFERENCE.md`

- If asked about **project config / tooling setup / eslint / prettier / tsconfig / Makefile**:
  - Load: `.governance/ai/core/inference-rules/project-type-detection.md`
  - Load relevant templates from: `docs/_shared/templates/project-configs/`
  - Scan for marker files before suggesting configs

- If asked about **cost / efficiency / token usage / model selection**:
  - Load: `.governance/ai/core/inference-rules/cost-optimization.md`
  - Load: `.governance/ai/core/inference-rules/cost-optimal-routing.md`
  - Check: `.ai/ledger/EFFICIENCY.md` for tracking data

- If asked about **wiring / setup / lazy loading / how things connect**:
  - Load: `.governance/ai/core/inference-rules/wiring-guide.md`
  - Load: `.governance/ai/core/inference-rules/lazy-loading.md`
  - Load: `.governance/ai/core/inference-rules/three-tier-system.md`

- If asked about **<YOUR DOMAIN AREA>**:
  - Load: <PATHS HERE> (example: `src/`, `infra/`, `docs/architecture/`)

---

## Disallowed / noisy directories (avoid unless explicitly required)

- node_modules/
- dist/
- build/
- vendor/
- .terraform/
- .venv/
- .cache/

---

## Maintenance rules

- When a new top-level directory is introduced, update the layout table.
- When ownership changes, update the Owner column.
- When docs move, update the document locations table.
