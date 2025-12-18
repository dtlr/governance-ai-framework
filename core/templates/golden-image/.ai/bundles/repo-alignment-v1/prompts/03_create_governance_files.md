# Prompt 03: Create Governance Files

## Context
Gap report generated. Now create missing governance files.

## Task
Create `.governance/` and `.governance-local/` structure.

## Instructions

1. **Read the plan**:
   ```
   .ai/_scratch/alignment-plan.md
   .ai/_scratch/repo-shape.md
   ```

2. **Create directories** (if missing):
   ```bash
   mkdir -p .governance
   mkdir -p .governance-local
   ```

3. **Create `manifest.json`** (if missing):
   - Use template from golden-image
   - Customize `entrypoints` based on project type
   - Set correct `governance_root` path

4. **Create `DIRECTORY_CONTRACT.md`** (if missing):
   - Copy from golden-image template
   - Add repo-specific directories to classification

5. **Create `.governance-local/overrides.yaml`** (if missing):
   - Use template
   - Set `project_type` from shape analysis
   - Configure `max_files_per_batch` based on repo size

6. **Create/update `CLAUDE.md`** (if missing or >4k tokens):
   - Use minimal pointer-based template
   - Keep under 2k tokens
   - Include safety rules and routing table

7. **Verify `.gitignore`** includes:
   ```
   .governance-local/secrets/
   .ai/_scratch/
   ```

## Validation
- `manifest.json` is valid JSON
- `overrides.yaml` is valid YAML
- All paths in manifest exist or will be created

## Completion
Say "Governance files created. Run prompt 04 to continue."
