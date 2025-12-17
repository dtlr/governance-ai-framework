# Universal Lazy Loading Inference Rules

## File System Strategy

All DTLR repositories use a dual-file AI documentation strategy:

### AGENTS.md - Universal AI Standard (agents.md/)
**Load when**: Need detailed understanding or troubleshooting
**Audience**: ANY AI coding agent (Cursor, Windsurf, Cline, Aider, Claude, etc.)
**Content**: Comprehensive technical documentation

### CLAUDE.md - Claude Code Specific (Anthropic)
**Load when**: Always (auto-loaded by Claude Code)
**Audience**: Claude Code CLI only
**Content**: Concise operational constraints and quick reference

## Core Inference Pointers

### 1. Starting Any Work
```
ALWAYS LOADED:
- Root CLAUDE.md (auto-loaded by Claude Code)

INFERENCE RULE:
IF working on specific module/component
THEN load <module>/CLAUDE.md
ELSE stay with root context
```

### 2. Need Detailed Understanding
```
TRIGGER PHRASES:
- "How does X work?"
- "Why was X designed this way?"
- "What are the edge cases for X?"
- "Troubleshoot X problem"
- "Explain the architecture"

ACTION:
Load <module>/AGENTS.md or root AGENTS.md
```

### 3. Security Questions
```
TRIGGER PHRASES:
- "Security impact"
- "RBAC changes"
- "Permission issues"
- "Hardcoded secret"
- "Vulnerability"

ACTION:
Load docs/_shared/security-policy.md (if exists)
OR load .governance/ai/core/conventions/security-baseline.md
```

### 4. Common Errors
```
TRIGGER PHRASES:
- "Error: ..."
- "Failed to ..."
- "How to fix ..."
- "Troubleshoot ..."
- "Debug ..."

ACTION:
1. Check repo-specific docs/_shared/troubleshooting.md first
2. If not found, check module AGENTS.md
3. Consider loading logs or error output files
```

### 5. Cross-Cutting Concerns
```
TRIGGER PHRASES:
- "How do we usually ..."
- "What's the standard ..."
- "Company policy on ..."
- "Team convention for ..."

ACTION:
Load .governance/ai/core/conventions/ files
```

## Lazy Loading Decision Tree

```
User asks question
    │
    ├─ Simple task (< 5 min)?
    │   └─ Use existing context (root CLAUDE.md)
    │
    ├─ Module-specific work?
    │   └─ Load module CLAUDE.md + module AGENTS.md (if needed)
    │
    ├─ Security/compliance?
    │   └─ Load security-policy.md + governance conventions
    │
    ├─ Complex troubleshooting?
    │   └─ Load AGENTS.md + troubleshooting.md + relevant logs
    │
    └─ Cross-repo pattern?
        └─ Load governance submodule files
```

## Anti-Patterns (Don't Do This)

❌ **Loading everything upfront** - Wastes tokens
❌ **Never loading additional context** - Misses important details
❌ **Loading repo-specific files for general questions** - Wrong context
❌ **Ignoring trigger phrases** - Misses inference opportunities

## Best Practices

✅ **Start with CLAUDE.md** - Always available, always relevant
✅ **Load progressively** - Add context as needed
✅ **Use trigger phrases** - Let language guide loading
✅ **Prefer specific over general** - Module docs over root docs
✅ **Check governance for patterns** - DRY across repos
