# Prompt 06: Verify Alignment

## Context
All files created. Now verify alignment and update ledger.

## Task
Validate the repository is properly aligned and log the operation.

## Instructions

1. **Run verification checks**:

   ```bash
   # Check manifest exists and is valid
   cat .governance/manifest.json | jq .
   
   # Check overrides exists
   cat .governance-local/overrides.yaml
   
   # Check CLAUDE.md token count
   wc -c CLAUDE.md
   
   # Check ledger exists
   ls -la .ai/ledger/
   
   # Check scratch is gitignored
   cat .ai/_scratch/.gitignore
   
   # Check router exists
   ls -la docs/_shared/router.md
   ```

2. **Generate verification report**:
   
   Output to `.ai/_scratch/alignment-verification.md`:
   ```markdown
   # Alignment Verification Report
   
   ## Checklist
   - [ ] manifest.json valid
   - [ ] overrides.yaml valid
   - [ ] CLAUDE.md < 2k tokens
   - [ ] LEDGER.md exists
   - [ ] EFFICIENCY.md exists
   - [ ] _scratch/.gitignore exists
   - [ ] router.md exists
   - [ ] DIRECTORY_CONTRACT.md exists
   
   ## Token Budget
   - CLAUDE.md: [X] tokens (target: <2000)
   - Total governance: [X] tokens
   
   ## Files Created
   - [list of new files]
   
   ## Files Modified
   - [list of modified files]
   ```

3. **Update LEDGER.md**:
   
   Add entry:
   ```markdown
   ## [Date] - Repository Alignment
   
   **Operation**: repo-alignment-v1 bundle execution
   **Files Created**: [count]
   **Files Modified**: [count]
   **Status**: Complete
   
   ### Changes
   - Created governance structure
   - Initialized AI artifacts
   - Created documentation routing
   
   ### Next Steps
   - Review generated files for repo-specific customization
   - Run repo-router-v1 bundle to refine router.md
   ```

4. **Output summary**:
   ```
   ══════════════════════════════════════════════════════════════
   ALIGNMENT COMPLETE
   ══════════════════════════════════════════════════════════════
   
   Created: [X] files
   Modified: [X] files
   Token budget: [X]/2000 (CLAUDE.md)
   
   Governance:  ✓ manifest.json, overrides.yaml, DIRECTORY_CONTRACT.md
   AI Artifacts: ✓ LEDGER.md, EFFICIENCY.md, _scratch/
   Documentation: ✓ router.md, AGENTS.md
   
   Next: Review generated files and customize for your project.
   ══════════════════════════════════════════════════════════════
   ```

## Completion
Say "Alignment verified. Repository is now governance-compliant."
