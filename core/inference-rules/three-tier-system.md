# Three-Tier Hierarchical Documentation System

**Pattern Name**: Hierarchical Context Architecture with Agent-Directed Retrieval
**Source**: repo-ssibility implementation
**Applies To**: Monorepos, large projects with multiple modules/packages

## Overview

The three-tier system optimizes AI agent context loading within token budgets through progressive disclosure and lazy loading.

## Core Principles

1. **Hierarchical Loading**: Load broader context first, drill down as needed
2. **Lazy Loading**: Never preload deep documentation
3. **Token Budget Discipline**: Strict allocation across tiers
4. **Agent-Directed Retrieval**: AI decides what to load based on task
5. **Single Source of Truth**: Each piece of information in exactly one place

## The Three Tiers

```
┌─────────────────────────────────────────────────────────────┐
│ TIER 1: Root Context (ALWAYS LOAD)                         │
│ File: /CLAUDE.md                                            │
│ Size: ~2K tokens (~1% of 200K budget)                      │
│ Purpose: Project overview, navigation, critical rules      │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ TIER 2: Module Context (LOAD ON DEMAND)                    │
│ Files: <module>/CLAUDE.md                                  │
│ Size: ~2K tokens per module                                │
│ Purpose: Module-specific architecture, quick reference     │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ TIER 3: Deep Dive (LAZY LOAD ONLY)                         │
│ Files: <module>/docs/*.md, <module>/AGENTS.md              │
│ Size: 5-10K tokens each                                    │
│ Purpose: Detailed implementation, troubleshooting          │
└─────────────────────────────────────────────────────────────┘
```

## Context Resolution Algorithm

### Tier 1: Root CLAUDE.md (Always Active)

**When**: First action in any conversation

**Contains**:
- Project structure overview
- Technology stack
- Critical universal rules
- Module descriptions (1-2 sentences)
- Navigation protocol
- Common commands

**Does NOT Contain**:
- Module-specific implementation details
- Code examples
- API documentation
- Troubleshooting guides

**Token Budget**: ~2K tokens (1% of total)

### Tier 2: Module CLAUDE.md (Lazy Load)

**Triggers**:
- User edits files under `<module>/`
- User explicitly mentions the module
- Working on module-specific feature

**Contains**:
- Module purpose and characteristics
- Quick start commands
- File structure overview
- Key dependencies
- Common patterns
- Testing strategy
- Links to Tier 3 (but doesn't load them)

**Does NOT Contain**:
- Line-by-line code explanations
- Complete API documentation
- Detailed troubleshooting

**Token Budget**: ~2K tokens per module (load 1-2 max = 2-4K, 1-2% of total)

### Tier 3: Deep Dive Docs (Lazy Load Only)

**Triggers**:
- "How does X work in detail?"
- "Troubleshoot X problem"
- "Explain the full X implementation"
- Starting fresh work on complex feature

**Contains**:
- Detailed API documentation
- Architecture flow diagrams
- Database schema explanations
- Troubleshooting guides
- Historical development notes
- Complex integration patterns

**Token Budget**: ~5-10K tokens per doc (load 1-3 max = 5-30K, 2.5-15% of total)

## Implementation Guidelines

### For Monorepos

```
repo/
├── CLAUDE.md                    # Tier 1: Root context
├── package-a/
│   ├── CLAUDE.md                # Tier 2: Package context
│   ├── AGENTS.md                # Tier 3: Deep dive
│   └── docs/
│       ├── api.md               # Tier 3: Detailed docs
│       └── troubleshooting.md   # Tier 3: Debugging
└── package-b/
    ├── CLAUDE.md
    └── AGENTS.md
```

### For IaC Repos

```
iac-repo/
├── CLAUDE.md                    # Tier 1: Deployment order, critical rules
├── module-0/
│   ├── CLAUDE.md                # Tier 2: Module specifics
│   └── AGENTS.md                # Tier 3: Detailed operations
└── module-1/
    ├── CLAUDE.md
    └── AGENTS.md
```

## Token Conservation Rules

| ✅ DO | ❌ DON'T |
|------|---------|
| Use Read/Grep to find patterns | Load CLAUDE.md for how-to guides |
| Reference: "Per Root CLAUDE.md line X" | Copy-paste or restate rules |
| Load module context only when needed | Pre-load all module docs |
| Explicitly discard when switching contexts | Keep stale context in memory |
| Execute immediately | Say "I've read the docs..." |

## Context Switching Protocol

When moving between modules:

```
Statement: "Discarding [module-a] context, loading [module-b] context."
Action: Load module-b/CLAUDE.md, release module-a context
```

## Example Workflow

```
User: "Add authentication to package-a"

AI Actions:
1. ✅ Already have Tier 1 (Root CLAUDE.md) loaded
2. ✅ Load Tier 2: packages/package-a/CLAUDE.md
3. ✅ Use Read tool to examine existing auth code
4. ✅ Implement feature
5. ⚠️ If stuck: Load Tier 3: packages/package-a/docs/authentication.md

User: "Now update package-b database"

AI Actions:
1. ✅ State: "Discarding package-a context, loading package-b context"
2. ✅ Load Tier 2: packages/package-b/CLAUDE.md
3. ✅ Continue work
```

## Benefits

- **Scalability**: Works with 10+ modules in monorepo
- **Efficiency**: 95%+ of token budget available for work
- **Clarity**: Always know what context is loaded
- **Flexibility**: Load more context as needed
- **Predictability**: Consistent loading pattern across conversations
