# RUN: Feature Planning Pipeline (v1)

**Mission**: Transform user input into validated, executable implementation plans.

## Input Required

This bundle requires a **user request** describing:
- What they want to build/change
- Target module or area (if known)
- Any constraints or preferences

Store input in: `.ai/_scratch/user-request.md`

## Pipeline Flow

```
┌─────────────────────────────────────────────────────────────┐
│  USER INPUT                                                 │
│  "Add Redis caching to the Azure module"                   │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  00_understand_request.md                                   │
│  → Parse intent, identify scope, clarify ambiguities        │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  01_research_codebase.md                                    │
│  → Scan relevant modules, understand current state          │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  02_research_docs.md                                        │
│  → Load DOCUMENTATION_STANDARDS.md, query official sources  │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  03_validate_approach.md                                    │
│  → Check best practices, identify risks, push back if bad   │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  04_generate_feature.md                                     │
│  → Create FEATURE.md with user story, acceptance criteria   │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  05_generate_pdr.md                                         │
│  → Create PDR.md with problem, solution, risks              │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  06_decompose_tasks.md                                      │
│  → Break into atomic tasks (<50 lines, 1-2 files each)      │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  07_generate_prompts.md                                     │
│  → Create executable prompt files (00, 01, 02...)           │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  OUTPUT: Ready for headless execution                       │
│  .ai/_scratch/feature-<name>/                               │
│  ├── FEATURE.md                                             │
│  ├── PDR.md                                                 │
│  ├── tasks.json                                             │
│  └── prompts/                                               │
│      ├── 00_setup.md                                        │
│      ├── 01_implement_core.md                               │
│      └── ...                                                │
└─────────────────────────────────────────────────────────────┘
```

## Usage

### Option 1: Interactive (with Claude)
```bash
# 1. Write your request
echo "Add Redis caching to reduce database load on user lookups" > .ai/_scratch/user-request.md

# 2. Run interactively
# Paste each prompt from prompts/ into Claude in order
```

### Option 2: Headless (via script)
```bash
# 1. Write your request  
echo "Add Redis caching..." > .ai/_scratch/user-request.md

# 2. Run pipeline
.governance/ai/core/automation/plan-feature.sh
```

## Output Structure

After running, you'll have:
```
.ai/_scratch/feature-redis-cache/
├── FEATURE.md           # User story, acceptance criteria
├── PDR.md               # Problem, solution, risks, tradeoffs
├── research/
│   ├── codebase.md      # Relevant code analysis
│   └── docs.md          # Official documentation notes
├── validation.md        # Risk analysis, push-back notes
├── tasks.json           # DAG of atomic tasks
└── prompts/
    ├── 00_context.md    # Shared context for all prompts
    ├── 01_task.md       # First implementation task
    ├── 02_task.md       # Second implementation task
    └── ...
```

## Execution of Generated Prompts

```bash
# Execute the generated prompts
for prompt in .ai/_scratch/feature-*/prompts/[0-9]*.md; do
  claude -p "$(cat "$prompt")" --allowedTools Edit,Write,Bash
done
```
