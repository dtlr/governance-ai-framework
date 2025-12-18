# Function Manifest - Dependency & Artifact Tracking

This document maps automation functions to their artifacts for cleanup.

## Quick Reference

| Script | Creates | Cleans Up With |
|--------|---------|----------------|
| `align-repo.sh` | `.ai/_scratch/ALIGNMENT_PLAN-*.md` | `--destroy` |
| `plan-feature.sh` | `.ai/_scratch/feature-*/` | `--destroy` |
| `plan-feature.sh --research` | `.ai/_scratch/research-*/` | `--destroy` |
| `cloud_architect.sh` | `.ai/_scratch/prompts/` | `--destroy` |

---

## align-repo.sh

### Functions → Artifacts

| Function | Creates | Depends On |
|----------|---------|------------|
| `discover_tooling()` | `.ai/TOOLING.md` | None |
| `analyze_golden_image()` | Compares files | `GOLDEN_IMAGE` path |
| `update_gitignore()` | Updates `.gitignore` | None |
| `generate_plan_document()` | `.ai/_scratch/ALIGNMENT_PLAN-*.md` | All analysis functions |

### Artifact Registry

```
.ai/_scratch/
├── ALIGNMENT_PLAN-{SESSION}.md    # Dry-run output
├── DEFERRED_ALIGNMENT.md          # --defer fallback
└── DEFERRED_ISSUE.txt             # --defer with gh CLI

# On --apply:
.ai/TOOLING.md                     # Created
*.bak-{SESSION}                    # Backup files
```

---

## plan-feature.sh

### Functions → Artifacts

| Function | Creates | Depends On |
|----------|---------|------------|
| `log_to_planning()` | `.ai/ledger/PLANNING.md` | None |
| `create_defer_issue()` | GitHub issue or `.md` | Feature artifacts |
| `find_latest_feature()` | None (query) | Feature directory |

### Artifact Registry

```
.ai/_scratch/
├── user-request.md                # User input
├── feature-{SESSION}/
│   ├── FEATURE.md                 # Feature spec
│   ├── PDR.md                     # Product design record
│   ├── tasks.json                 # Task breakdown
│   ├── REVIEW.md                  # Prioritized review
│   ├── research/                  # Research artifacts
│   ├── prompts/                   # Execution prompts
│   │   ├── 00_init.md
│   │   ├── 01_*.md
│   │   └── ...
│   └── *.log                      # Execution logs
└── research-{SESSION}/            # --research mode
    ├── research-plan.md
    └── research-findings.md
```

---

## cloud_architect.sh

### Functions → Artifacts

| Function | Creates | Depends On |
|----------|---------|------------|
| `find_latest_prompts()` | None (query) | `OUTPUT_DIR` |
| Context gathering | `00_context.md` | Repo CLAUDE.md files |
| Research phase | `01_plan.md`, `.research_output.md` | Ollama |
| Task generation | `02_task_*.md` | Research output |
| Manifest generation | `MANIFEST.json` | All task files |

### Artifact Registry

```
.ai/_scratch/prompts/
├── 00_context.md                  # Repo context
├── 01_plan.md                     # Research plan
├── 02_task_01.md                  # Task 1
├── 02_task_02.md                  # Task 2
├── ...
├── MANIFEST.json                  # Execution manifest
├── DEFERRED.md                    # --defer fallback
└── DEFERRED_ISSUE.txt             # --defer with gh CLI
```

---

## Cleanup Patterns

### By Session
```bash
# Find all artifacts from a session
find .ai/_scratch -name "*20251218-*" -type f
find .ai/_scratch -name "*20251218-*" -type d
```

### By Type
```bash
# Alignment artifacts
rm -rf .ai/_scratch/ALIGNMENT_PLAN-*.md

# Feature artifacts  
rm -rf .ai/_scratch/feature-*/

# Research artifacts
rm -rf .ai/_scratch/research-*/

# Cloud architect artifacts
rm -rf .ai/_scratch/prompts/
```

### Full Reset
```bash
# Clean ALL scratch artifacts (preserves README.md)
find .ai/_scratch -mindepth 1 -not -name "README.md" -not -name ".gitignore" -delete
```

---

## Dependency Graph

```
┌─────────────────────────────────────────────────────────────┐
│                    USER REQUEST                              │
└─────────────────────────┬───────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        ▼                 ▼                 ▼
┌───────────────┐ ┌───────────────┐ ┌───────────────┐
│ align-repo.sh │ │plan-feature.sh│ │cloud_architect│
└───────┬───────┘ └───────┬───────┘ └───────┬───────┘
        │                 │                 │
        ▼                 ▼                 ▼
┌───────────────┐ ┌───────────────┐ ┌───────────────┐
│ALIGNMENT_PLAN │ │ FEATURE.md    │ │ 01_plan.md    │
│     .md       │ │ PDR.md        │ │ 02_task_*.md  │
│               │ │ tasks.json    │ │ MANIFEST.json │
└───────┬───────┘ └───────┬───────┘ └───────┬───────┘
        │                 │                 │
        └─────────────────┼─────────────────┘
                          │
              ┌───────────┼───────────┐
              ▼           ▼           ▼
        ┌──────────┐ ┌──────────┐ ┌──────────┐
        │ --apply  │ │ --defer  │ │--destroy │
        │ Execute  │ │ GH Issue │ │ Cleanup  │
        └──────────┘ └──────────┘ └──────────┘
```

---

## Adding New Functions

When adding new functions, update this manifest:

1. Add function to the appropriate script section
2. Document what artifacts it creates
3. Document its dependencies
4. Add cleanup pattern if needed
5. Update the dependency graph if it changes flow
