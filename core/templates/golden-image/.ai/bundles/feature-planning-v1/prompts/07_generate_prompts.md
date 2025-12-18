# Prompt 07: Generate Executable Prompts

## Context
Tasks decomposed. Now generate prompts for headless execution.

## Input
Read:
- `.ai/_scratch/feature-<name>/FEATURE.md`
- `.ai/_scratch/feature-<name>/PDR.md`
- `.ai/_scratch/feature-<name>/tasks.json`

## Task
Generate executable prompt files that can be run via `claude -p`.

## Instructions

### 1. Create prompts directory
```bash
mkdir -p .ai/_scratch/feature-<name>/prompts
```

### 2. Generate 00_context.md (shared context)

This file is prepended to every task prompt:

```markdown
# Context: [Feature Name]

## Feature Summary
[From FEATURE.md - 2-3 sentences]

## Technical Approach
[From PDR.md - key decisions]

## Files Involved
- [file1.tf]: [purpose]
- [file2.tf]: [purpose]

## Conventions
- Use existing patterns from [reference file]
- Follow [style guide]
- Verify with: [command]

## Safety Rules
- NEVER modify files outside scope
- ALWAYS run verification after changes
- COMMIT after each successful task
```

### 3. Generate task prompts (01_task.md, 02_task.md, ...)

For each task in tasks.json, generate:

```markdown
# Task [ID]: [Task Name]

## Context
[Include 00_context.md content OR reference]

## Objective
[From task description]

## Files to Modify
- `[file path]`: [what to change]

## Instructions

1. [Step 1 - specific action]
2. [Step 2 - specific action]
3. [Step 3 - specific action]

## Expected Changes

```hcl
# [filename]
# Add/modify this section:
[code snippet showing expected result]
```

## Verification

```bash
[verification command from tasks.json]
```

Expected output:
- [What success looks like]

## Rollback

If verification fails:
```bash
[rollback command from tasks.json]
```

## Completion

After successful verification:
1. Stage changes: `git add [files]`
2. Commit: `git commit -m "feat([scope]): [task description]"`
3. Say: "Task [ID] complete. [summary of changes]"
```

### 4. Generate execution script

Create `.ai/_scratch/feature-<name>/execute.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

FEATURE_DIR="$(dirname "$0")"
CONTEXT=$(cat "$FEATURE_DIR/prompts/00_context.md")

for prompt in "$FEATURE_DIR"/prompts/[0-9][0-9]_*.md; do
  if [[ "$prompt" == *"00_context"* ]]; then continue; fi
  
  echo "Executing: $(basename "$prompt")"
  
  # Prepend context to prompt
  FULL_PROMPT="$CONTEXT

$(cat "$prompt")"
  
  claude -p "$FULL_PROMPT" --allowedTools Edit,Write,Bash
  
  echo "✓ Complete: $(basename "$prompt")"
done
```

### 5. Output Structure

```
.ai/_scratch/feature-<name>/
├── FEATURE.md
├── PDR.md
├── tasks.json
├── execute.sh          # Runner script
├── research/
│   ├── codebase.md
│   └── docs.md
├── validation.md
└── prompts/
    ├── 00_context.md   # Shared context
    ├── 01_setup.md     # Task 1
    ├── 02_implement.md # Task 2
    └── ...
```

## Final Checklist

- [ ] All prompts reference 00_context.md
- [ ] Each prompt has verification command
- [ ] Each prompt has rollback command
- [ ] Each prompt has commit message
- [ ] execute.sh is executable
- [ ] Total prompts match tasks.json count

## Completion

Output summary:
```
══════════════════════════════════════════════════════════════
FEATURE PLANNING COMPLETE: [feature-name]
══════════════════════════════════════════════════════════════

Generated:
  ✓ FEATURE.md       - User story, acceptance criteria
  ✓ PDR.md           - Technical design record
  ✓ tasks.json       - [N] atomic tasks
  ✓ prompts/         - [N] executable prompts

Execution:
  # Option 1: Run all prompts
  .ai/_scratch/feature-<name>/execute.sh

  # Option 2: Run individually
  claude -p "$(cat .ai/_scratch/feature-<name>/prompts/01_*.md)"

Estimated effort: [X] tasks, [Y] total lines

══════════════════════════════════════════════════════════════
```
