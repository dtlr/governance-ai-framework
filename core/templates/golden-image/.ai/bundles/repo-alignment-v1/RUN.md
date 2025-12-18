# RUN: Repository Alignment Bundle (v1)

**Mission**: Align any repository with the governance golden-image structure.

## Prerequisites

1. Governance submodule initialized at `.governance/ai`
2. Claude Code or compatible AI assistant
3. Write access to the repository

## Load First (Context)

```
.governance/ai/00_INDEX/README.md
.governance/ai/core/templates/golden-image/  (reference structure)
.governance/manifest.json (if exists)
CLAUDE.md (if exists)
```

## Execution Flow

```
┌─────────────────────────────────────────────────────────────┐
│  00_discover_repo_shape.md                                  │
│  → Inventory current structure, detect project type         │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  01_compare_to_golden.md                                    │
│  → Diff against golden-image, identify gaps                 │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  02_generate_gap_report.md                                  │
│  → Output structured gap analysis to .ai/_scratch/          │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  03_create_governance_files.md                              │
│  → Create .governance/, .governance-local/, manifest.json   │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  04_create_ai_artifacts.md                                  │
│  → Create .ai/ structure, ledger, inference, bundles        │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  05_create_docs_structure.md                                │
│  → Create docs/_shared/, router.md, project-specific docs   │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  06_verify_alignment.md                                     │
│  → Final validation, update LEDGER.md, summary              │
└─────────────────────────────────────────────────────────────┘
```

## Output

After execution:
- `.ai/_scratch/alignment-report.md` - Gap analysis
- `.ai/_scratch/alignment-plan.md` - Implementation plan
- All missing governance files created
- `.ai/ledger/LEDGER.md` updated with changes

## Headless Execution

```bash
# From repo root (after governance submodule init)
for prompt in .governance/ai/core/templates/golden-image/.ai/bundles/repo-alignment-v1/prompts/*.md; do
  claude -p "$(cat "$prompt")" --allowedTools Edit,Write,Bash
done
```

## Manual Execution

Run prompts in order: `00 → 01 → 02 → 03 → 04 → 05 → 06`

Each prompt is atomic and can be re-run if interrupted.
