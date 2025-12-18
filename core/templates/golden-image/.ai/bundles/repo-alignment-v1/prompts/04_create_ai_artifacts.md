# Prompt 04: Create AI Artifacts

## Context
Governance files created. Now create `.ai/` structure.

## Task
Create the AI artifacts directory structure.

## Instructions

1. **Create directory structure**:
   ```bash
   mkdir -p .ai/ledger
   mkdir -p .ai/_scratch
   mkdir -p .ai/inference
   mkdir -p .ai/bundles
   ```

2. **Create `.ai/_scratch/.gitignore`**:
   ```
   # Ephemeral files - NEVER commit
   *
   !.gitignore
   ```

3. **Create `.ai/ledger/LEDGER.md`**:
   - Use template from golden-image
   - Initialize with header and empty log section
   - Include column definitions

4. **Create `.ai/ledger/EFFICIENCY.md`**:
   - Use template from golden-image
   - Initialize cost tracking tables
   - Add operation type definitions

5. **Create `.ai/inference/README.md`**:
   - Explain purpose of inference rules
   - List any repo-specific rules needed
   - Point to governance inference rules

6. **Copy relevant bundles** (if applicable):
   - `repo-router-v1` - for router maintenance
   - `ai-file-governance-v1` - for governance updates
   - Skip project-config bundles unless needed

## File Classification
All files created here are **Category B** (AI governance artifacts).

## Validation
- `.ai/_scratch/.gitignore` prevents commits
- `LEDGER.md` has correct structure
- `EFFICIENCY.md` has tracking tables

## Completion
Say "AI artifacts created. Run prompt 05 to continue."
