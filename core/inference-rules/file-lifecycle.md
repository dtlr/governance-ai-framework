# Inference: File Lifecycle & Management Rules

## Intent
Define how individual files are created, updated, moved, deprecated, and deleted.

## Decision Rules

### Create (only when necessary)
Create a new file only if:
- no existing file satisfies the purpose, AND
- its location matches the directory contract, AND
- it is classified A/B/C before writing

### Update (preferred)
Prefer updating existing authoritative docs/configs. Keep diffs small and reviewable.

### Move (rehoming)
If a file is in the wrong location:
- move it to the canonical directory
- optionally leave a short redirect stub if needed

### Deprecate (safe dedupe)
When duplicates exist:
- choose one source of truth
- add a deprecation note to others (pointer + date + reason)
- delete only when approved or safe

### Delete (ephemeral by default)
- Delete anything in `.ai/_scratch/` at end of run unless user requests retention.
- If retained, move to `.ai/_out/` and reference ledger.

### Versioning semantics
- `.governance/ai/` is versioned by submodule pointer.
- Wrapper + overrides are versioned in consuming repo.
- Bundles are versioned in consuming repo (or distributed via golden image).

### Naming conventions
- Prefer kebab-case.
- Use `INFERENCE.md` in topic directories for inference docs.

## Output Contracts (per run)
- Ledger entry appended to `.ai/ledger/LEDGER.md`
- File Ledger Summary printed

## Failure Conditions
- Any tracked file under `.ai/_scratch/`
- Any new top-level directory without approval
- Any file created without A/B/C classification
