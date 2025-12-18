# Inference: Directory Contract (What Each Directory Contains)

## Intent
Ensure every file created or modified by an AI agent has a **clear home**, consistent semantics, and an explicit lifecycle.

This inference document is **process-level**: it applies across many prompts and repos that adopt this golden image.

## Inputs
- `.governance/manifest.json`
- `.governance-local/overrides.yaml`
- Repository tree and existing docs

## Decision Rules

### Rule 1 — Every file must have a home (A/B/C)
Before writing any file, classify it:
- **A**: Long-living repo artifact (ships with repo)
- **B**: Long-living AI governance artifact (governs process / repeatable work)
- **C**: Ephemeral working artifact (safe to delete)

### Rule 2 — Canonical homes by directory
Use the table below. If a file does not match any allowed home, **do not create it**—propose a location and wait for approval.

| Directory | Allowed contents | Class | Notes |
|---|---|---:|---|
| `.governance/` | Wrapper contract: `manifest.json`, wrapper README, adoption notes | B | Repo-owned; points to submodule |
| `.governance/ai/` | **Submodule** governance source-of-truth | (submodule) | Do not edit from consuming repo |
| `.governance-local/` | Repo-specific overrides, toggles, integrations | B | Human-reviewable |
| `.ai/ledger/` | Append-only audit logs of AI actions | B | Update every run |
| `.ai/bundles/` | Executable planning bundles (RUN + PDR + FEATURE + prompts) | B | Re-runnable |
| `.ai/inference/` | Process-level decision frameworks | B | Stable; reused |
| `.ai/prompts/` | Task-level prompts (thin) | B | Reference inference |
| `.ai/eval/` | Validation criteria, gates, checklists | B | CI/manual |
| `.ai/_out/` | Generated outputs explicitly approved to keep | B | Must reference ledger |
| `.ai/_scratch/` | Temporary working files, scans, drafts | C | Never commit; safe to delete |
| `docs/` | Repo documentation (runbooks, policies, deployment notes) | A | Durable docs |
| `docs/_shared/` | Cross-cutting references | A | Avoid duplication |
| `src/`, `infra/`, etc. | Implementation artifacts | A | Only when implementing accepted work |

### Rule 3 — No new top-level directories
AI must not create new top-level directories beyond the contract.

### Rule 4 — Prefer edits over new files
If an equivalent doc exists:
1) update it, or
2) add a short redirect and deprecate duplicates

### Rule 5 — Provenance for durable generated outputs
Durable “generated” artifacts must:
- live in `.ai/_out/` (or `docs/` if it becomes official),
- reference originating bundle/prompt + ledger entry.

## Output Contracts
Every run must print and record:
- Created / Modified / Deleted files
- A/B/C classification for each
- Scratch cleanup status

## Anti-patterns
- Creating `tmp/`, `output/`, `generated/` outside `.ai/_scratch/` / `.ai/_out/`
- Committing scratch artifacts
- Duplicating governance rules across repos without clear authority
