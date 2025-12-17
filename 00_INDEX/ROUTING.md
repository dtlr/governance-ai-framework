# Governance Routing Decision Tree

**Purpose**: Detailed logic for what context to load based on user task


## Routing Algorithm

### Step 1: Classify Task Type

```
INPUT: User's message
OUTPUT: Task classification

IF message contains infrastructure keywords (deploy, apply, plan, tofu, terraform):
    → TASK_TYPE = "infrastructure_operation"
ELSE IF message contains module reference (module X, X-*, specific module name):
    → TASK_TYPE = "module_specific"
ELSE IF message contains exploratory keywords (show, explain, list, all):
    → TASK_TYPE = "exploratory"
ELSE IF message contains file operation keywords (fix, update, edit, add, delete):
    → TASK_TYPE = "file_operation"
ELSE IF message contains debugging keywords (error, fail, broke, troubleshoot):
    → TASK_TYPE = "debugging"
ELSE:
    → TASK_TYPE = "general"
```


## Step 2: Determine Context Tier

### For `infrastructure_operation`
```
TIER = 2 (Module Context)

REQUIRED:
- Module CLAUDE.md (target module)
- deployment-safety.md (safety rules)
- overrides.yaml (dependencies, credentials)

OPTIONAL (load if mentioned):
- STATE_CACHE.md (if user says "show current state first")
- troubleshooting.md (if previous failures mentioned)

EXAMPLE:
User: "Deploy module 3"
Load: 3-azure-0/CLAUDE.md, deployment-safety.md, overrides.yaml
Execute: Deployment workflow
```


### For `module_specific`
```
TIER = 2 (Module Context)

REQUIRED:
- Module CLAUDE.md (mentioned module)
- Module AGENTS.md (if operational details needed)

OPTIONAL:
- Related module CLAUDE.md files (if dependencies mentioned)
- overrides.yaml (if checking config)

EXAMPLE:
User: "Explain how module 5 works"
Load: 5-az-containers/CLAUDE.md, 5-az-containers/AGENTS.md
Present: Module overview, purpose, dependencies
```


### For `exploratory`
```
IF scope is "all" or "full" or "entire":
    TIER = 3 (Deep Dive)
    REQUIRED:
    - STATE_CACHE.md
    - All module CLAUDE.md files (load progressively)
    - Architecture docs
ELSE IF scope is specific (e.g., "show me Azure resources"):
    TIER = 2 (Focused Exploration)
    REQUIRED:
    - Relevant module CLAUDE.md files only
    - STATE_CACHE.md (filtered view)
ELSE:
    TIER = 1 (Root Only)
    REQUIRED:
    - Root CLAUDE.md
    - Directory structure overview

EXAMPLES:
User: "Show me all infrastructure"
→ Tier 3: Load STATE_CACHE.md, all modules

User: "Show me Azure resources"
→ Tier 2: Load 3-azure-0, 4-azure-1, 5-az-containers, filtered STATE_CACHE

User: "What's in this repo?"
→ Tier 1: Root CLAUDE.md only
```


### For `file_operation`
```
TIER = 1 (Root Context Only)

IF file is in module directory:
    ADD: Module CLAUDE.md (for context)
ELSE:
    STAY: Tier 1 only

EXAMPLES:
User: "Fix typo in README"
→ Tier 1: No additional loading

User: "Update 3-azure-0/main.tf"
→ Tier 1 + Module: Load 3-azure-0/CLAUDE.md for context
```


### For `debugging`
```
TIER = 2 + Troubleshooting

REQUIRED:
- Relevant module CLAUDE.md
- docs/_shared/troubleshooting.md
- Recent command output (ask user if not provided)

OPTIONAL:
- STATE_CACHE.md (if state-related issue)
- deployment-safety.md (if deployment failed)

EXAMPLE:
User: "Module 7 deployment failed"
Load: 7-datadog/CLAUDE.md, troubleshooting.md
Ask: "What was the error message?"
```


### For `general`
```
TIER = 1 (Root Context Only)

REQUIRED:
- Root CLAUDE.md (overview)
- governance README (if governance-related)

WAIT: For user clarification before loading more

EXAMPLE:
User: "Hello"
→ Tier 1: Greet, explain capabilities, ask what they need
```


## Step 3: Dependency Resolution

### For Infrastructure Operations
```
IF operation targets module X:
    CHECK overrides.yaml → modules[X].depends_on
    IF dependencies exist:
        FOR EACH dependency:
            VERIFY deployed (check STATE_CACHE.md or ask user)
            IF NOT deployed:
                WARN user: "Module X depends on module Y, which is not deployed"
                SUGGEST: Deploy dependencies first or verify state
```

**Example**:
```
User: "Deploy module 5"
Check: overrides.yaml shows depends_on: [3-azure-0, 4-azure-1]
Verify: Are modules 3 and 4 deployed?
If yes: Proceed
If no: Warn user and explain deployment order
```


## Step 4: Context Loading Sequence

### Tier 1 (Always)
```
LOAD_ORDER:
1. .governance/ai/00_INDEX/README.md
2. .governance/ai/core/rules/SYSTEM.md
3. .governance/ai/core/rules/AGENT_CONTRACT.md
4. .governance/ai/iac/conventions/deployment-safety.md
5. .governance/ai/terraform/conventions/tofu-standards.md
6. CLAUDE.md (root)
7. .governance-local/overrides.yaml
```


### Tier 2 (On-Demand: Module)
```
LOAD_ORDER (in addition to Tier 1):
1. <module>/CLAUDE.md (target module)
2. Check dependencies in overrides.yaml
3. IF dependencies exist:
   - Load dependency module CLAUDE.md files (context only)
4. IF operational details needed:
   - <module>/AGENTS.md
```


### Tier 3 (Explicit: Deep Dive)
```
LOAD_ORDER (in addition to Tier 1):
1. STATE_CACHE.md (full cached state)
2. All module CLAUDE.md files (load progressively as needed)
3. docs/architecture/*.md (architecture diagrams, design docs)
4. docs/_shared/troubleshooting.md
5. docs/_shared/security-policy.md (if security-related)
```

**Note**: Don't load all Tier 3 files at once. Load progressively based on conversation.


## Trigger Phrase Mapping

### Infrastructure Keywords
| Phrase | Action | Load |
|--------|--------|------|
| "deploy module X" | Deploy workflow | Tier 2: X/CLAUDE.md + safety |
| "apply module X" | Deploy workflow | Tier 2: X/CLAUDE.md + safety |
| "plan module X" | Generate plan | Tier 2: X/CLAUDE.md + safety |
| "validate module X" | Pre-flight check | Tier 2: X/CLAUDE.md |
| "destroy module X" | Destruction (rare) | Tier 2: X/CLAUDE.md + user confirmation |


### Exploratory Keywords
| Phrase | Action | Load |
|--------|--------|------|
| "show me state" | Display state | Tier 3: STATE_CACHE.md |
| "show all resources" | Full inventory | Tier 3: STATE_CACHE.md + all modules |
| "list modules" | Module overview | Tier 1: overrides.yaml |
| "explain architecture" | Architecture review | Tier 3: docs/architecture/ |
| "what's deployed" | Deployment status | Tier 2: STATE_CACHE.md (summary) |


### Module-Specific Keywords
| Phrase | Action | Load |
|--------|--------|------|
| "work on module X" | Module context | Tier 2: X/CLAUDE.md |
| "explain module X" | Module details | Tier 2: X/CLAUDE.md + X/AGENTS.md |
| "what does module X do" | Module purpose | Tier 2: X/CLAUDE.md (overview) |
| "module X dependencies" | Dependency check | Tier 2: overrides.yaml + dependencies |


### Debugging Keywords
| Phrase | Action | Load |
|--------|--------|------|
| "error in module X" | Debug workflow | Tier 2: X/CLAUDE.md + troubleshooting |
| "deployment failed" | Failure analysis | Tier 2: relevant module + troubleshooting |
| "troubleshoot X" | Debug support | Tier 2: X/CLAUDE.md + troubleshooting |
| "something broke" | General debug | Ask for specifics, then load Tier 2 |


### File Operation Keywords
| Phrase | Action | Load |
|--------|--------|------|
| "fix typo in X" | File edit | Tier 1 (Tier 2 if module file) |
| "update X file" | File edit | Tier 1 (Tier 2 if module file) |
| "create X file" | File creation | Tier 1 (Tier 2 if module file) |
| "delete X file" | File deletion | Tier 1 (Tier 2 if module file) |


## Special Cases

### User Asks About Governance Itself
```
EXAMPLES:
- "How does governance work?"
- "What's in .governance/?"
- "Explain the three-tier system"

ACTION:
Load: .governance/README.md
Present: Governance overview
Offer: Load architecture docs if they want details
```


### User Provides No Context
```
EXAMPLES:
- "Help me"
- "What can you do?"
- "I'm stuck"

ACTION:
Stay: Tier 1
Respond: Explain capabilities, ask what they need
Wait: For clarification before loading more
```


### User References Multiple Modules
```
EXAMPLE:
"Compare modules 3 and 5"

ACTION:
Load: Tier 2
- 3-azure-0/CLAUDE.md
- 5-az-containers/CLAUDE.md
Present: Comparison of purpose, dependencies, resources
```


### User Wants to Make Breaking Change
```
EXAMPLES:
- "Delete production database"
- "Destroy all resources"
- "Change deployment order"

ACTION:
Load: Tier 2 (relevant context)
Warn: Explicitly about consequences
Require: Explicit confirmation before proceeding
Suggest: Backup/safety measures
```


## Token Budget Enforcement

### Before Loading Context
```
CURRENT_TOKENS = estimate_current_context()

IF task requires Tier 3:
    ESTIMATED_TOTAL = CURRENT_TOKENS + 40000
    IF ESTIMATED_TOTAL > 80000:
        WARN user: "This will load significant context"
        SUGGEST: "Would you like me to load progressively?"
```


### Progressive Loading (Tier 3)
```
Instead of loading everything:

LOAD: STATE_CACHE.md first
PRESENT: High-level summary
ASK: "Would you like details on a specific area?"

IF user specifies area:
    LOAD: Only relevant module CLAUDE.md files
    PRESENT: Detailed view of that area

IF user wants everything:
    LOAD: Remaining module files one at a time
    PRESENT: Incrementally
```


## Anti-Patterns (DON'T DO THIS)

### ❌ Load Everything Upfront
```
DON'T:
On session start → Load all modules + STATE_CACHE + all docs

WHY:
- Wastes 60k+ tokens
- Slower responses
- Most context irrelevant to task

DO INSTEAD:
Load Tier 1 → Wait for task → Load appropriate tier
```


### ❌ Guess What User Needs
```
DON'T:
User: "Work on module 3"
You: *Loads modules 3, 4, 5, STATE_CACHE, all docs*

WHY:
- Loading too much context
- Making assumptions about scope

DO INSTEAD:
Load only module 3 → Ask if they need related context
```


### ❌ Skip Dependency Checks
```
DON'T:
User: "Deploy module 5"
You: *Immediately starts deployment without checking dependencies*

WHY:
- Module 5 depends on modules 3 and 4
- Deployment will fail if dependencies not deployed

DO INSTEAD:
Check overrides.yaml → Verify dependencies → Warn if missing → Proceed if OK
```


## Routing Decision Examples

### Example 1: Simple File Edit
```
User: "Fix the typo in README.md where it says 'recieve'"

CLASSIFICATION: file_operation
TIER: 1 (root only)
CONTEXT_NEEDED: None additional
ACTION: Read README.md → Fix typo → Commit
TOKENS: ~15k (Tier 1 only)
```


### Example 2: Module Deployment
```
User: "Deploy module 7 to production"

CLASSIFICATION: infrastructure_operation
TIER: 2 (module + safety)
CONTEXT_NEEDED:
- 7-datadog/CLAUDE.md
- deployment-safety.md
- overrides.yaml (check dependencies: modules 1, 5)
ACTION:
1. Verify modules 1 and 5 deployed
2. Run validation
3. Generate saved plan
4. User reviews
5. Apply plan
6. Update cache
7. Commit
TOKENS: ~25k (Tier 1 + Tier 2)
```


### Example 3: Architecture Review
```
User: "Explain the full infrastructure architecture"

CLASSIFICATION: exploratory (scope: full)
TIER: 3 (deep dive)
CONTEXT_NEEDED:
- STATE_CACHE.md
- docs/architecture/governance-unified.md
- All module CLAUDE.md files (progressive)
ACTION:
1. Load STATE_CACHE.md
2. Present high-level overview
3. Ask which area they want details on
4. Load specific modules progressively
5. Present architecture diagram
TOKENS: ~60k (Tier 1 + Tier 3, loaded progressively)
```


### Example 4: Debugging
```
User: "Module 3 deployment failed with authentication error"

CLASSIFICATION: debugging
TIER: 2 + troubleshooting
CONTEXT_NEEDED:
- 3-azure-0/CLAUDE.md
- docs/_shared/troubleshooting.md
- docs/_shared/credentials.md (auth-related)
ACTION:
1. Load module context
2. Check credential requirements in overrides.yaml
3. Suggest validation steps
4. Load troubleshooting guide
5. Provide resolution steps
TOKENS: ~30k (Tier 1 + Tier 2 + troubleshooting)
```


## Summary: Routing Checklist

For every user message:
- [ ] Classify task type (6 categories)
- [ ] Determine context tier (1, 2, or 3)
- [ ] Check for dependencies (infrastructure ops)
- [ ] Load context in proper order (sequential)
- [ ] Stop when sufficient context loaded
- [ ] Explicitly state what you loaded (transparency)
- [ ] Track token budget (warn if heavy)
- [ ] Use progressive loading for Tier 3

**Goal**: Load minimum context needed for task, escalate only when necessary.
