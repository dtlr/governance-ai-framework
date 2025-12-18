# Governance & AI Documentation Structure

This document describes the **governance system layout** and the **global AI documentation hierarchy** in this repository. It intentionally avoids repo-specific infrastructure/module details.

## Governance system (Git submodule + local config)

### Submodule declaration

- `.gitmodules` declares the governance framework submodule at **`.governance/ai`**.

### Governance root directory

The governance entrypoint directory is:

- `.governance/`
  - `.governance/manifest.json`: **Discovery contract** for AI context loading
  - `.governance/README.md`: Explains governance layers and design goals
  - `.governance/ai/`: **Git submodule** containing shared governance rules

### Governance submodule structure (high level)

- `.governance/ai/`
  - `00_INDEX/`: **AI entrypoint + routing**
  - `core/`: Universal behavioral rules, inference rules, and conventions
  - `iac/`: Infrastructure-as-code safety conventions
  - `terraform/`: Terraform/OpenTofu-specific conventions and standards
  - `VERSION`, `CHANGELOG.md`, `CONTRIBUTING.md`: Versioning and maintenance

### Repo-local governance config (not a submodule)

- `.governance-local/`
  - `overrides.yaml`: **Repository-specific configuration** consumed by governance (policy toggles, module lists, integrations, etc.)

## Router: files you touch to *set up / template / validate / update / commit* governance

Use this section as a decision router: **what you’re trying to do** → **which files/scripts matter** → **what must be committed**.

### A) Initialize the submodule (new clone / new machine)

- **Where it’s declared**: `.gitmodules` (must include `.governance/ai`)
- **How it initializes automatically**: `.envrc` (direnv) calls `git submodule update --init .governance/ai` when missing
- **Manual init** (if direnv isn’t used): `git submodule update --init --recursive .governance/ai`

**Commit requirements**:
- ✅ Commit: `.gitmodules` and the **submodule pointer** at `.governance/ai` (this is how Git records the pinned commit)
- ❌ Never commit changes *inside* `.governance/ai/` in the parent repo (that’s owned by the submodule repository)

### B) Create the required wrapper files (what makes governance “work” in a repo)

- **Discovery contract (required)**: `.governance/manifest.json`
  - Points to `governance_root: ".governance/ai"`
  - Lists `entrypoints` (Tier 1 load set)
  - Points to local config via `local_overrides`
- **Repo-local config (recommended)**: `.governance-local/overrides.yaml`
- **Human overview (recommended)**: `.governance/README.md`

**Commit requirements**:
- ✅ Commit: `.governance/manifest.json`, `.governance/README.md` (if used), `.governance-local/overrides.yaml`

### C) Template/bootstrap “AI client settings” and other reusable boilerplate

- **Templates live in the submodule**:
  - `.governance/ai/core/templates/settings.local.json.template`
- **How to apply templates**: follow `.governance/ADOPTION_GUIDE.md` (canonical instructions)

**Commit requirements**:
- ✅ Commit: the resulting repo-local settings files you choose to add (template application output)
- ✅ Commit: updates to `.governance/manifest.json` if you change entrypoints/optional context
- ❌ Do not edit template sources inside `.governance/ai/` from the consuming repo

### D) Update governance to a newer version (pin a new submodule commit/tag)

- **Preferred workflow**: `scripts/update_governance.sh`
  - `--status`: show current pinned version
  - (no args): checkout latest tag on `origin/main` (or `origin/main` head if no tags)
  - `<tag>`: checkout a specific tag (e.g., `v1.2.0`)
- **Alternative/implicit workflow**: `.envrc` supports `GOVERNANCE_AUTO_UPDATE=true` (uses `git submodule update --remote`)

**Commit requirements**:
- ✅ Commit: `.governance/ai` (the submodule pointer change)
- (Sometimes) ✅ Commit: updates to wrapper files if the new governance version requires them (manifest/overrides/docs)

### E) Validate compliance / generate reports / restore “golden image”

- **Compliance checker**: `scripts/check_governance_compliance.sh`
  - Validates: submodule presence, required entrypoints, `manifest.json` JSON validity + entrypoint count, override existence, “no submodule mods”, etc.
  - `--report` writes: `GOVERNANCE_COMPLIANCE_REPORT.md` (generated artifact)
- **Restoration playbook (prompt)**: `docs/governance/COMPLIANCE_RESTORATION_PROMPT.md`
- **Adoption reference**: `.governance/ADOPTION_GUIDE.md`

**Commit requirements**:
- ✅ Commit: real fixes (manifest/overrides/docs/scripts) as needed
- ⚠️ Usually do **not** commit `GOVERNANCE_COMPLIANCE_REPORT.md` unless you want it tracked as an artifact

### F) One-time conversion of governance *into* a submodule (for maintainers)

- **Conversion script**: `scripts/convert_to_submodule.sh`
  - Removes `.governance/ai` directory from git tracking
  - Adds it back as a git submodule
  - Commits both steps
- **Conversion record**: `SUBMODULE_CONVERSION_COMPLETE.md` (human audit trail)

**Commit requirements**:
- ✅ Commit: `.gitmodules` + `.governance/ai` submodule pointer changes + any script updates

## AI prompt / inference context structure

This repository is designed for **lazy loading**: AI agents load a small, deterministic “root prompt” first and then expand context on-demand.

### Canonical entry contract (`.governance/manifest.json`)

The manifest defines:

- **`governance_root`**: where governance docs live (the submodule root)
- **`entrypoints`**: minimal files to load at session start (behavior + safety + standards)
- **`optional_context`**: additional inference/routing docs that may be loaded on-demand
- **`local_overrides`**: the repo-local config file path (typically `.governance-local/overrides.yaml`)

### Routing and tiering entrypoint

- `.governance/ai/00_INDEX/README.md`:
  - Defines **routing triggers** (“if user asks X, load Y”)
  - Defines the **tier model** (root vs module vs deep dive)
  - Documents **prompt caching guidance** (what is cacheable vs should not be cached)

### Three-tier context model (structural view)

- **Tier 1 (Root context)**:
  - Governance entrypoints from `.governance/manifest.json`
  - Repo-local governance config: `.governance-local/overrides.yaml`
  - Root AI guidance documents (see below)

- **Tier 2 (Scoped context)**:
  - Scope-specific AI docs (typically module/directory level `CLAUDE.md` / `AGENTS.md`)

- **Tier 3 (Deep dive)**:
  - Cross-cutting reference docs (typically `docs/_shared/*`)
  - Generated “inventory/state” summaries (if present, e.g. `STATE_CACHE*.md`)

## Global AI documentation hierarchy (what lives where)

### Root-level AI guidance

- `CLAUDE.md`: **Quick constraints** and operational rules for AI agents (high-signal, short)
- `AGENTS.md`: **Detailed AI/operator guide** and repository map (long-form reference)

### Directory/module-level AI guidance pattern

Many directories follow this convention:

- `<scope>/CLAUDE.md`: scope-specific quick constraints and “do/don’t” rules
- `<scope>/AGENTS.md`: scope-specific operational playbook, troubleshooting, procedures

### Shared cross-cutting AI reference docs

- `docs/_shared/`: reusable “how-to / policy / troubleshooting” docs used across scopes
  - Examples: credentials, state/backend, security policy, troubleshooting, documentation strategy

### Governance-related human docs (optional but common)

- `docs/governance/` and `docs/architecture/` often contain human-focused governance summaries and architecture notes that complement the rules in `.governance/`.


## G) AI Artifact Lifecycle (Ledger + Scratch + Bundles)

- Durable AI artifacts live in: `.ai/`
- Ephemeral artifacts live in: `.ai/_scratch/` (never committed; safe to delete)
- Every AI run appends to: `.ai/ledger/LEDGER.md`
- Executable planning runs from: `.ai/bundles/<name>/RUN.md`
- AI must not create new top-level dirs beyond the golden image contract
