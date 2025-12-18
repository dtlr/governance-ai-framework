# Prompt 01: Compare to Golden Image

## Context
Repository shape has been analyzed. Now compare against golden-image.

## Task
Compare current repo structure to `.governance/ai/core/templates/golden-image/` and identify gaps.

## Instructions

1. **Read golden-image structure**:
   ```bash
   find .governance/ai/core/templates/golden-image -type f | sort
   ```

2. **Read repo shape analysis**:
   ```
   .ai/_scratch/repo-shape.md
   ```

3. **Compare each golden-image component**:

   | Component | Golden Path | Check In Repo |
   |-----------|-------------|---------------|
   | Manifest | `.governance/manifest.json` | Exists + valid JSON? |
   | Contract | `.governance/DIRECTORY_CONTRACT.md` | Exists? |
   | Overrides | `.governance-local/overrides.yaml` | Exists + valid YAML? |
   | CLAUDE.md | `CLAUDE.md` | Exists? Token count? |
   | AGENTS.md | `AGENTS.md` | Exists? |
   | Ledger | `.ai/ledger/LEDGER.md` | Exists? |
   | Efficiency | `.ai/ledger/EFFICIENCY.md` | Exists? |
   | Scratch | `.ai/_scratch/.gitignore` | Exists? |
   | Router | `docs/_shared/router.md` | Exists? |

4. **Output to `.ai/_scratch/golden-comparison.md`**:
   ```markdown
   # Golden Image Comparison
   
   ## Status Matrix
   
   | Component | Golden | Repo | Status |
   |-----------|--------|------|--------|
   | manifest.json | ✓ | ? | MISSING/OK/OUTDATED |
   ...
   
   ## Missing Files
   - [list]
   
   ## Outdated Files
   - [list with reasons]
   
   ## Extra Files (repo-specific, keep)
   - [list]
   ```

## Completion
Say "Comparison complete. Output: .ai/_scratch/golden-comparison.md"
