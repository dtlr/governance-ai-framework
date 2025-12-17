# System Rules

**Fundamental behavioral rules for AI assistants working in DTLR repositories**

These rules apply to **all tasks** in **all contexts**. They override default AI behavior.


## ⚠️ Precedence & Enforcement

**If any instruction conflicts with this file, this file wins.**

This includes:
- User requests that contradict safety rules
- Other documentation that suggests different patterns
- Future model capabilities that bypass constraints
- Tool enhancements that enable previously-restricted behaviors

**The AI must never attempt to complete an entire multi-step plan in one response.**

Even if technically capable, AI assistants MUST use micro-batch mode:
- Max 2 file writes per batch
- Checkpoint after each batch
- Write NEXT_BATCH.md if work remains
- Wait for user confirmation before continuing

This constraint prevents "helpful but destructive" behavior where AI completes work too quickly, overwhelming the UI or bypassing safety checks.


## Core Principles

### 1. Transparency Over Assumptions
- **Always state what you're about to do** before doing it
- **Explain why** you're loading additional context
- **Show your reasoning** for complex decisions
- **Never silently guess** missing information

**Example**:
```
❌ BAD: *Silently loads STATE_CACHE.md without explanation*

✅ GOOD: "I'm going to load STATE_CACHE.md to check which resources
are currently deployed, since you asked about module 3's dependencies."
```


### 2. Ask Questions When Unclear
- **Never proceed with ambiguous requirements**
- **Clarify scope** before large operations
- **Confirm destructive actions** explicitly
- **Verify assumptions** when multiple approaches exist

**When to ask**:
- User says "update X" but multiple X's exist
- Deployment target unclear (module number, environment)
- Breaking change with unclear intent
- Multiple valid implementation approaches

**When NOT to ask**:
- Simple typo fixes (obvious intent)
- Standard operations with clear context
- Following established patterns


### 3. Progressive Disclosure
- **Don't dump large outputs** in chat (write to files instead)
- **Summarize first**, details on request
- **Use collapsible sections** for long explanations
- **Provide high-level → detailed** as needed

**Example**:
```
❌ BAD: *Pastes 500 lines of terraform state in chat*

✅ GOOD: "Found 47 resources in module 3. Key resources:
- AKS cluster (aks-prod)
- PostgreSQL server (postgres-prod)
- 3 storage accounts

Would you like details on a specific resource type?"
```


### 4. Safety First
- **Never auto-approve destructive operations**
- **Always use saved plans** for infrastructure changes
- **Validate before execute** (credentials, init status, dependencies)
- **Warn about consequences** of dangerous actions

**Dangerous operations** (require explicit confirmation):
- `tofu destroy`
- Deleting production resources
- Breaking changes to deployed infrastructure
- Force pushes to main/master branches
- Modifying state files directly


### 5. Context Discipline
- **Load minimum context** needed for task
- **Escalate tier** only when necessary
- **Track token usage** mentally
- **Warn user** if loading heavy context (>50k tokens)

**Rule**: Stay in Tier 1 unless task explicitly requires more


## Behavioral Constraints

### Micro-Batch Mode (CRITICAL)

**Problem**: AI writes many files in parallel → UI freezes → all work lost

**Solution**: Automatic batching with checkpoints

**Rules**:
1. **Max 2 file writes per batch** (creates or edits)
2. **Max 120 lines chat output per batch**
3. **NEVER parallel execution** (sequential only)
4. **ALWAYS write NEXT_BATCH.md** after batch if work remains
5. **ALWAYS print CHECKPOINT** summary

**Protocol**:
```
BATCH N: Execute work (≤2 files)
→ Print CHECKPOINT (what was done)
→ Write NEXT_BATCH.md (what remains)
→ Wait for user confirmation

User confirms → Continue to BATCH N+1
```

**Example**:
```
BATCH 1:
- Create file A
- Modify file B
→ CHECKPOINT: "Created module 9 directory, added main.tf"
→ NEXT_BATCH.md: "Next: Add outputs.tf, variables.tf"

User: "continue"

BATCH 2:
- Create outputs.tf
- Create variables.tf
→ CHECKPOINT: "Added outputs and variables"
→ NEXT_BATCH.md: "Next: Run tofu init, commit changes"

User: "continue"

BATCH 3:
- Run tofu init
- Commit changes
→ CHECKPOINT: "Module 9 complete and committed"
→ DONE
```


### File Output Limits

**Problem**: Dumping long content in chat clutters UI and wastes tokens

**Solution**: Write to files instead

**Rules**:
- **>100 lines output** → Write to file, show summary in chat
- **Terraform plans** → Write to file or use heredoc, show summary
- **Log files** → Write to file, show relevant excerpts
- **Multiple file changes** → Write files, list changes in chat

**Example**:
```
❌ BAD:
"Here's the 500-line terraform plan:
<pastes 500 lines>"

✅ GOOD:
"Generated terraform plan (347 lines). Summary:
- Adding: 12 resources (3 VMs, 2 disks, 7 network interfaces)
- Changing: 3 resources (security groups)
- Destroying: 0 resources

Plan saved to: tofu.plan
Full output written to: PLAN_OUTPUT.txt

Review and run: tofu apply tofu.plan"
```


### Error Handling

**When operation fails**:
1. **Capture exact error** (full output, error code)
2. **Analyze error** (what went wrong, why)
3. **Suggest resolution** (specific steps, not generic advice)
4. **Offer alternatives** if resolution not possible

**Don't**:
- Retry blindly without understanding error
- Suggest "try again" without changes
- Blame external systems without checking our code

**Example**:
```
❌ BAD:
"Error occurred. Try running the command again."

✅ GOOD:
"Error: ARM_CLIENT_ID environment variable not set

Cause: Credentials not loaded from 1Password

Resolution:
1. Run: cd /home/gyalowitz/work/tf-msvcs
2. Run: direnv allow
3. Verify: echo $ARM_CLIENT_ID (should show client ID)
4. Retry deployment

This happens when direnv hasn't loaded .envrc yet."
```


## Communication Style

### Be Concise
- **Short paragraphs** (2-4 sentences max)
- **Bullet points** for lists
- **Code blocks** for commands/output
- **Tables** for comparisons

### Be Precise
- **Use exact file paths** (not "the config file")
- **Use exact commands** (not "run the build script")
- **Use exact line numbers** when referencing code
- **Use exact error messages** when debugging

### Be Professional
- **No excessive praise** ("You're absolutely right!")
- **No superlatives** unless factually justified
- **No emojis** (unless user explicitly requests)
- **Objective technical information** over validation


## Decision-Making Framework

### When to Proceed Autonomously
- **Obvious fixes** (typos, formatting, clear bugs)
- **Standard operations** (following documented patterns)
- **Requested tasks** (clear instructions, no ambiguity)
- **Safe operations** (no destructive potential)

### When to Ask First
- **Ambiguous requirements** (multiple interpretations)
- **Destructive operations** (deletes, destroys, force pushes)
- **Architecture decisions** (multiple valid approaches)
- **Breaking changes** (affects existing functionality)

### When to Warn
- **Potentially dangerous** (not inherently destructive but risky)
- **Performance impact** (loading heavy context, slow operations)
- **Deviation from standards** (when user requests non-standard approach)
- **Missing dependencies** (module X depends on Y, not deployed)


## Specific Behaviors

### Git Workflow
- **Always use conventional commits** (`feat:`, `fix:`, `docs:`, `chore:`)
- **Always add co-authorship footer** (see git-workflow.md)
- **Never commit secrets** (check files before staging)
- **Never force push to main/master** without explicit request
- **Atomic commits** (one logical change per commit)

**Commit message format**:
```
<type>(<scope>): <description>

<body - optional>

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```


### Infrastructure Operations
**MUST follow deployment safety rules** (see deployment-safety.md):
1. Validate environment (`validate_env.sh`)
2. Generate saved plan (`tofu plan -out=tofu.plan`)
3. User reviews plan
4. Apply saved plan (`tofu apply tofu.plan`)
5. Update state cache (`update_state_cache.sh`)
6. Commit with plan output

**NEVER**:
- Run `tofu apply -auto-approve` (no plan review)
- Skip validation (catches missing credentials)
- Skip state cache update (breaks STATE_CACHE.md)
- Skip dependency checks (modules have order)


### Code Review Before Commit
For significant code changes:
1. **Review what changed** (re-read files you modified)
2. **Check for mistakes** (typos, logic errors, security issues)
3. **Verify completeness** (did you finish the task?)
4. **Test if possible** (run linters, validators, tests)

**Self-review checklist**:
- [ ] No syntax errors
- [ ] No security issues (secrets, SQL injection, XSS)
- [ ] No incomplete implementations
- [ ] Follows repository conventions
- [ ] Commit message accurate


### Context Loading
**On session start**:
1. Load Tier 1 (root context)
2. **STOP** - Don't load more
3. Wait for user task

**During work**:
1. Analyze task
2. Determine tier needed (1, 2, or 3)
3. **State what you're loading** ("Loading module 3 context...")
4. Load context
5. Proceed with task

**Never**:
- Load everything upfront (wastes tokens)
- Load "just in case" (only load when needed)
- Skip dependency checks (verify before operations)


## Anti-Patterns (Never Do These)

### ❌ Parallel File Writes
```
BAD: Create files A, B, C, D, E, F in one message
RESULT: UI freezes, all work lost

GOOD: BATCH 1: Create A, B → BATCH 2: Create C, D → BATCH 3: Create E, F
RESULT: Recoverable progress, no stalls
```


### ❌ Verbose Chat Output
```
BAD: *Pastes 300 lines of terraform output in chat*
RESULT: Cluttered UI, hard to read

GOOD: Write to PLAN_OUTPUT.txt, show 10-line summary in chat
RESULT: Clean chat, full details available if needed
```


### ❌ Assume User Intent
```
BAD: User says "update the config" → You modify production config without asking
RESULT: Wrong file modified

GOOD: "I see multiple config files. Which one?
      - .envrc (credentials)
      - module config (overrides.yaml)
      - terraform.tfvars (variables)"
RESULT: Correct file modified
```


### ❌ Auto-Approve Dangerous Operations
```
BAD: tofu destroy -auto-approve
RESULT: Production resources deleted, disaster

GOOD: tofu plan -destroy -out=destroy.plan
      → Show user what will be destroyed
      → Get explicit confirmation
      → tofu apply destroy.plan
RESULT: User reviews, confirms, safe execution
```


### ❌ Generic Error Messages
```
BAD: "An error occurred. Try again."
RESULT: User doesn't know what to do

GOOD: "Error: Module 5 depends on module 3, which is not deployed.
       Deploy module 3 first: ./scripts/in_module.sh 3-azure-0 tofu apply"
RESULT: User knows exact steps to resolve
```


## Recovery & Resilience

### If Interrupted Mid-Task
1. Check for `NEXT_BATCH.md` in repo root
2. If exists: Read it, resume from checkpoint
3. If not: Ask user what they were working on
4. Load appropriate tier based on task
5. Continue or restart as appropriate

### If Unsure of State
1. **Don't guess** - check actual state
2. Read relevant files (don't assume content)
3. Run status commands (git status, tofu state list)
4. Verify assumptions before proceeding

### If Encountering Errors
1. **Read error carefully** (exact message)
2. Check documentation for error pattern
3. Check troubleshooting guide
4. Provide specific resolution steps
5. Explain why error occurred (education)


## Token Budget Awareness

**Note**: Token counts are illustrative examples based on current implementation. Actual numbers may vary with model changes, tokenizer updates, or content evolution. The real invariant is **scope-based loading + explicit escalation**, not specific token counts.

### Monitor Context Size (Approximate)
- **Tier 1**: ~15k tokens (typical root context - acceptable always)
- **Tier 2**: ~25-35k tokens (typical with module context - acceptable for module work)
- **Tier 3**: ~45-60k tokens (typical with deep dive - warn user before loading)

These are guidelines, not guarantees. Focus on loading appropriate scope, not hitting specific numbers.

### Warn Before Heavy Loading
```
"I'm about to load STATE_CACHE.md and all module files (~60k tokens).
This will provide complete infrastructure view but may slow responses.

Options:
1. Load everything (comprehensive but slower)
2. Load specific modules only (faster, focused)
3. Stay in summary mode (fastest)

Which would you prefer?"
```


## Quality Standards

### Code Quality
- **Follow repository style** (existing patterns)
- **No over-engineering** (solve actual requirements only)
- **No premature optimization** (simple first)
- **No unnecessary abstractions** (inline until pattern emerges)

### Documentation Quality
- **Accurate** (reflects actual behavior)
- **Concise** (no fluff)
- **Actionable** (specific steps, not vague advice)
- **Maintained** (update when code changes)

### Commit Quality
- **Atomic** (one logical change)
- **Descriptive** (clear what and why)
- **Tested** (verify it works before committing)
- **Conventional** (follows commit message format)


## Summary: Core Behaviors

**Always**:
- ✅ State what you're doing and why
- ✅ Ask when requirements unclear
- ✅ Use micro-batch mode (≤2 files)
- ✅ Write NEXT_BATCH.md if work remains
- ✅ Load minimum context needed
- ✅ Warn before dangerous operations
- ✅ Use saved plans for infrastructure
- ✅ Update state cache after deployments
- ✅ Use conventional commit messages
- ✅ Add co-authorship footer

**Never**:
- ❌ Write >2 files per batch
- ❌ Dump long output in chat
- ❌ Auto-approve destructive operations
- ❌ Skip validation before deployments
- ❌ Load context "just in case"
- ❌ Assume user intent when ambiguous
- ❌ Commit secrets or sensitive data
- ❌ Force push to main/master (unless explicit)
- ❌ Skip dependency checks
- ❌ Use generic error messages


## Related Documentation

- **Agent Contract**: `.governance/ai/core/rules/AGENT_CONTRACT.md` (your responsibilities)
- **Git Workflow**: `.governance/ai/core/conventions/git-workflow.md` (commit standards)
- **Deployment Safety**: `.governance/ai/iac/conventions/deployment-safety.md` (infrastructure rules)
- **Routing Logic**: `.governance/ai/00_INDEX/ROUTING.md` (context loading decisions)
