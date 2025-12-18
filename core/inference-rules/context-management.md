# Inference: Context Management & Session Lifecycle

## Intent

Define when to clear context, how to preserve critical state, and when to suggest session transitions. Prevent context exhaustion while maintaining work continuity.

---

## Context Thresholds

| Usage | Status | Action |
|-------|--------|--------|
| **0-50%** | ✅ Healthy | Continue working normally |
| **50-70%** | ⚠️ Awareness | Note: "Context at X%, may need to manage soon" |
| **70-80%** | 🟡 Caution | Suggest options (see below) |
| **80-90%** | 🟠 Action Required | Must take action before continuing major work |
| **90%+** | 🔴 Critical | Stop new work, preserve state immediately |

---

## At 70-80%: Suggest Options

When context reaches 70-80%, AI MUST inform user and offer choices:

```
Context is at X% (Yk/200k tokens). Options:

1. **Continue** - Proceed with ~Zk tokens remaining
2. **Compact** - Use /compact to summarize and reclaim space
3. **Handoff** - Create summary doc for new session
4. **Commit & Close** - Commit current work, start fresh session

Recommendation: [based on work state]
```

### Decision Factors

| Factor | Recommendation |
|--------|----------------|
| In middle of multi-file change | Continue or Compact |
| Just finished a logical unit | Commit & Close |
| Need to preserve complex state | Handoff document |
| Simple remaining work | Continue |

---

## Handoff Document Pattern

When creating a handoff for session continuity:

**Location:** `.ai/_scratch/HANDOFF-YYYY-MM-DD.md` (or ledger entry)

**Template:**
```markdown
# Session Handoff - YYYY-MM-DD

## Work Completed
- [List of completed items]

## Current State
- Branch: `feature/xyz`
- Last commit: `abc123 - "commit message"`
- Files modified but uncommitted: [list]

## Work Remaining
- [ ] Task 1
- [ ] Task 2

## Critical Context
- [Key decisions made]
- [Important constraints discovered]
- [Patterns to follow]

## Reproduction
To continue this work:
1. `git checkout feature/xyz`
2. Read this handoff
3. Continue from [specific point]
```

---

## Ledger Entry for Session Close

When closing a session due to context limits, add to ledger:

```markdown
## YYYY-MM-DD — Session Close (Context Limit)

**Agent:** Claude Opus 4.5
**Result:** PARTIAL (context exhausted)

### Usage Metrics
- **Tokens:** Input: Xk, Output: Yk, Total: Zk
- **Cost:** $X.XX
- **Context:** 180k/200k tokens (90%)

### Work Completed
- [List]

### Work Remaining
- [List with pointers to where to resume]

### Handoff Created
- Location: `.ai/_scratch/HANDOFF-YYYY-MM-DD.md`
- Or: See above "Work Remaining"
```

---

## Proactive Context Management

### During Session

AI SHOULD proactively manage context by:

1. **Discarding stale context** when switching tasks
   ```
   "Discarding [module-a] context, loading [module-b] context"
   ```

2. **Not re-reading files** already in context
   - Reference: "Per earlier read of file.ts..."
   - Don't: Read same file 3+ times

3. **Using pointers** instead of copying content
   - Reference: "See line 45-60 of config.ts"
   - Don't: Paste entire file contents

4. **Batching related operations** to avoid repeated context loading

### Red Flags

| Pattern | Problem | Fix |
|---------|---------|-----|
| Same file read 3+ times | Context waste | Reference earlier read |
| Context >150k on simple task | Over-loading | Discard and reload lean |
| Full file copies in chat | Token waste | Use line references |
| Multiple unrelated contexts | Scope creep | Focus on one task |

---

## Integration with Cost Tracking

Context management directly impacts cost:

| Context Level | Cost Impact |
|---------------|-------------|
| 50k context | ~$0.75 input (Opus) |
| 100k context | ~$1.50 input (Opus) |
| 150k context | ~$2.25 input (Opus) |
| 200k context | ~$3.00 input (Opus) |

**Rule:** If context is high but work is simple, consider:
1. Starting fresh session (lower input cost)
2. Using cheaper model for remaining work

---

## Automatic Behaviors

### At Session Start
- Note starting context level
- Plan for context budget

### During Work
- Track context growth
- Warn at thresholds

### Before Major Operations
- Check if context allows completion
- Suggest pause point if insufficient

### At Session End
- Log final context level in ledger
- Create handoff if work remains

---

## Commands Reference

| Command | Effect |
|---------|--------|
| `/context` | Show current context usage |
| `/compact` | Summarize and reduce context |
| `/clear` | Clear conversation (loses state) |

---

## Failure Conditions

- ❌ Context at 90%+ without warning user
- ❌ Session ended without handoff when work remains
- ❌ Same file read 3+ times without justification
- ❌ No ledger entry for context-exhausted session
