# Prompt 06: Decompose into Atomic Tasks

## Context
FEATURE.md and PDR.md generated. Now break into atomic implementation tasks.

## Input
Read:
- `.ai/_scratch/feature-<name>/FEATURE.md`
- `.ai/_scratch/feature-<name>/PDR.md`

## Task
Decompose the feature into atomic tasks that can be executed independently.

## Atomic Task Constraints

Each task MUST:
- [ ] Edit **≤ 50 lines** of code
- [ ] Touch **≤ 2 files**
- [ ] Be **independently verifiable**
- [ ] Have **clear success criteria**
- [ ] Include **rollback path**

## Instructions

### 1. Identify Task Categories

| Category | Description |
|----------|-------------|
| SETUP | Create files, directories, boilerplate |
| IMPLEMENT | Write core logic |
| CONFIGURE | Update configuration, variables |
| INTEGRATE | Connect components |
| VALIDATE | Add validation, testing |
| DOCUMENT | Update documentation |
| CLEANUP | Remove temporary code, refactor |

### 2. Build Task DAG (Directed Acyclic Graph)

Identify dependencies between tasks:
```
[SETUP] → [IMPLEMENT_CORE] → [INTEGRATE]
                ↓
         [IMPLEMENT_HELPER]
                ↓
         [VALIDATE] → [DOCUMENT]
```

### 3. For Each Task, Define:

```json
{
  "id": "01",
  "name": "task-name",
  "category": "IMPLEMENT",
  "description": "What this task accomplishes",
  "depends_on": ["00"],
  "files": ["path/to/file.tf"],
  "estimated_lines": 30,
  "verification": "tofu validate && tofu plan",
  "rollback": "git checkout -- path/to/file.tf"
}
```

### 4. Output to `.ai/_scratch/feature-<name>/tasks.json`:

```json
{
  "feature": "feature-name",
  "total_tasks": 5,
  "estimated_total_lines": 150,
  "tasks": [
    {
      "id": "00",
      "name": "setup-foundation",
      "category": "SETUP",
      "description": "Create file structure and boilerplate",
      "depends_on": [],
      "files": ["module/main.tf"],
      "estimated_lines": 20,
      "verification": "tofu validate",
      "rollback": "rm module/main.tf"
    },
    {
      "id": "01",
      "name": "implement-core-resource",
      "category": "IMPLEMENT",
      "description": "Add the primary resource block",
      "depends_on": ["00"],
      "files": ["module/main.tf"],
      "estimated_lines": 40,
      "verification": "tofu plan -target=resource.name",
      "rollback": "git checkout -- module/main.tf"
    }
  ],
  "execution_order": ["00", "01", "02", "03", "04"]
}
```

### 5. Validate Decomposition

Check:
- [ ] No task exceeds 50 lines
- [ ] No task touches >2 files
- [ ] All dependencies are acyclic
- [ ] Every task has verification command
- [ ] Total tasks ≤ 10 (if >10, reconsider scope)

## Completion
Say "Tasks decomposed. [N] atomic tasks created. Ready to generate prompts."
