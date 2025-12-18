# Prompt 02: Generate Gap Report

## Context
Comparison complete. Now generate actionable gap report.

## Task
Create a structured implementation plan for closing the gaps.

## Instructions

1. **Read comparison results**:
   ```
   .ai/_scratch/repo-shape.md
   .ai/_scratch/golden-comparison.md
   ```

2. **Categorize gaps by priority**:
   
   **P0 - Critical (Blocks AI operation)**:
   - `manifest.json` missing
   - `CLAUDE.md` missing or >4k tokens
   - `.ai/_scratch/` not gitignored
   
   **P1 - Important (Degrades efficiency)**:
   - `LEDGER.md` missing
   - `EFFICIENCY.md` missing
   - `router.md` missing
   
   **P2 - Nice to have (Improves consistency)**:
   - `DIRECTORY_CONTRACT.md` missing
   - `AGENTS.md` missing
   - `DOC_STRATEGY.md` missing

3. **Generate file creation plan**:
   - Which template to use
   - What customization needed
   - Dependencies between files

4. **Output to `.ai/_scratch/alignment-plan.md`**:
   ```markdown
   # Alignment Implementation Plan
   
   ## Summary
   - P0 gaps: [count]
   - P1 gaps: [count]
   - P2 gaps: [count]
   - Estimated prompts: [count]
   
   ## P0 Critical
   
   ### 1. [File name]
   - Template: [golden-image path]
   - Customization: [what needs repo-specific content]
   - Creates: [output path]
   
   ## P1 Important
   ...
   
   ## P2 Nice to Have
   ...
   
   ## Execution Order
   1. [file] - reason
   2. [file] - reason
   ...
   ```

## Completion
Say "Gap report complete. Output: .ai/_scratch/alignment-plan.md"
