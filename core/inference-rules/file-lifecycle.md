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

### Global Reusability Assessment
After creating any script, utility, or custom tool, assess whether it has **global applicability**:

**Assessment Questions:**
1. Could this be useful in other repositories?
2. Is it generic enough to work across different projects?
3. Does it solve a common problem not specific to this repo?

**If YES to any:**
1. **Propose templating** - Suggest adding to governance framework templates
2. **Identify customization points** - Mark `<PLACEHOLDER>` values that vary per-repo
3. **Document when to use** - Add "When to Use" and "When NOT to Use" sections
4. **File in appropriate location**:
   - Scripts → `core/templates/golden-image/docs/_shared/templates/project-configs/_common/`
   - Config patterns → Appropriate stack directory (javascript/, python/, etc.)
   - Inference rules → `core/inference-rules/`

**Examples of globally reusable items:**
- Validation scripts (lint, format, test runners)
- CI/CD helper scripts
- Environment setup scripts
- Development workflow automation
- Cross-project utility functions

**Examples of repo-specific items (do NOT template):**
- Scripts referencing specific paths/resources
- Project-specific business logic
- One-off data migrations
- Integration with proprietary systems

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

### Ledger Entry Requirements (MANDATORY)
Every ledger entry MUST include usage metrics:

| Field | Format | Example |
|-------|--------|---------|
| **Tokens** | Input: X, Output: Y, Total: Z | Input: 85k, Output: 45k, Total: 130k |
| **Cost** | $X.XX with calculation | $4.60 (85k×$15/1M + 45k×$75/1M) |
| **Context** | Xk/200k tokens | 120k/200k tokens |

**Why mandatory:**
- Cost visibility for budget tracking
- Efficiency analysis across operations
- Model selection optimization (cost vs quality)
- Historical data for capacity planning

**Cost calculation:** `(input_tokens × input_rate / 1M) + (output_tokens × output_rate / 1M)`

See `.ai/ledger/LEDGER.md` header for current model pricing.

## Failure Conditions
- Any tracked file under `.ai/_scratch/`
- Any new top-level directory without approval
- Any file created without A/B/C classification
