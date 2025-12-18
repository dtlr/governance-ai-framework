# Prompt 00: Discover Repository Shape

## Context
You are aligning this repository to the governance golden-image structure.

## Task
Inventory the current repository structure and detect its project type.

## Instructions

1. **Scan root directory** for marker files:
   ```
   package.json     → JavaScript/TypeScript
   go.mod           → Go
   Cargo.toml       → Rust
   pyproject.toml   → Python
   *.tf             → Terraform/OpenTofu
   Dockerfile       → Docker
   .github/         → GitHub Actions
   ```

2. **Check for existing governance**:
   - `.governance/manifest.json` exists?
   - `CLAUDE.md` exists?
   - `.ai/` directory exists?
   - `docs/_shared/router.md` exists?

3. **Identify repo characteristics**:
   - Monorepo or single project?
   - Has submodules?
   - Number of top-level directories
   - Presence of existing documentation

4. **Output to `.ai/_scratch/repo-shape.md`**:
   ```markdown
   # Repository Shape Analysis
   
   ## Project Type
   - Primary: [detected type]
   - Secondary: [if multi-type]
   
   ## Existing Governance
   - manifest.json: [yes/no]
   - CLAUDE.md: [yes/no]
   - .ai/ structure: [yes/no/partial]
   - docs/_shared/router.md: [yes/no]
   
   ## Structure
   - Type: [monorepo/single]
   - Submodules: [list or none]
   - Top-level dirs: [count]
   
   ## Marker Files Found
   - [list of marker files]
   ```

## Completion
Say "Shape analysis complete. Output: .ai/_scratch/repo-shape.md"
