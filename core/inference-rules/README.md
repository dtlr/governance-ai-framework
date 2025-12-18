# Inference Rules Index

**AI behavioral rules that govern how agents work across all repositories.**

These rules are **global** - they apply to every repository using the governance submodule. For repo-specific rules, use `.ai/inference/` in the consuming repository.

---

## Rule Catalog

| Rule | File | Purpose | Load When |
|------|------|---------|-----------|
| **Lazy Loading** | `lazy-loading.md` | Load context on-demand, not upfront | Always (Tier 1) |
| **Three-Tier System** | `three-tier-system.md` | Progressive context disclosure | Always (Tier 1) |
| **Directory Contract** | `directory-contract.md` | A/B/C file classification | Creating files |
| **File Lifecycle** | `file-lifecycle.md` | Create/update/delete workflow | Modifying files |
| **Repo Router** | `repo-router.md` | Directory→purpose mapping | Navigating repo |
| **Submodule Management** | `submodule-management.md` | Governance version/update workflow | Updating governance |
| **Cookbook Patterns** | `claude-cookbook-patterns.md` | Efficiency/accuracy patterns from Anthropic | Optimization tasks |
| **Project Type Detection** | `project-type-detection.md` | Detect project stacks, guide config relevance | Creating configs, suggesting tooling |
| **Cost Optimization** | `cost-optimization.md` | Track prompt-to-cost patterns, efficiency feedback | Every session (mandatory tracking) |
| **Cost-Optimal Routing** | `cost-optimal-routing.md` | Tiered routing strategy, minimize AI costs | Designing pipelines, model selection |
| **Wiring Guide** | `wiring-guide.md` | How to connect lazy loading components | Setting up new repos, debugging wiring |
| **Context Management** | `context-management.md` | Session lifecycle, context thresholds, handoffs | Context >70%, session transitions |

---

## Rule Summaries

### Lazy Loading (`lazy-loading.md`)
**Core principle**: Don't load everything upfront. Load context based on what the task requires.

Key points:
- Tier 1 (always): Root context, core rules
- Tier 2 (on-demand): Module-specific context
- Tier 3 (explicit): Deep dive, full state

### Three-Tier System (`three-tier-system.md`)
**Core principle**: Progressive disclosure of context based on task complexity.

Key points:
- Tier 1: ~15k tokens, simple tasks
- Tier 2: +10-20k tokens, module work
- Tier 3: +20k+ tokens, architecture reviews

### Directory Contract (`directory-contract.md`)
**Core principle**: Every file must be classified as A, B, or C.

Key points:
- Class A: Repo artifacts (code, configs, docs)
- Class B: AI governance artifacts (ledger, bundles, inference)
- Class C: Ephemeral (scratch, plans, temp files)

### File Lifecycle (`file-lifecycle.md`)
**Core principle**: Follow a checklist before creating/modifying files.

Key points:
- Check .gitignore before creating
- Validate with `git status` after
- Never create in wrong classification zone

### Repo Router (`repo-router.md`)
**Core principle**: Understand what each directory is for before working in it.

Key points:
- Map directories to purposes
- Follow existing patterns
- Don't create files in wrong locations

### Submodule Management (`submodule-management.md`)
**Core principle**: Clear 5-step workflow for governance updates.

Key points:
1. Validate current state
2. Modify framework repo
3. Version and tag
4. Update consuming repos
5. Validate installation

### Cookbook Patterns (`claude-cookbook-patterns.md`)
**Core principle**: Efficiency and accuracy patterns from Anthropic's official cookbooks.

Key patterns:
- Prompt caching (90% cost reduction, 2x latency improvement)
- Context compaction (58% token savings)
- Extended thinking (improved accuracy)
- Orchestrator-workers (complex task decomposition)
- Evaluator-optimizer (iterative refinement)

### Project Type Detection (`project-type-detection.md`)
**Core principle**: Detect project types from marker files and suggest only relevant configs.

Key points:
- Marker file scanning (package.json, go.mod, *.tf, etc.)
- Negative inference (when configs are NOT relevant)
- Polyglot/monorepo handling (multiple stacks)
- Config templates: `core/templates/golden-image/docs/_shared/templates/project-configs/`

### Cost Optimization (`cost-optimization.md`)
**Core principle**: Create feedback loop between prompts and costs to continuously improve efficiency.

Key points:
- Mandatory tracking: Tokens, Cost, Context in every ledger entry
- Cost expectations by operation type (explore, create, refactor, etc.)
- Model selection rules (Haiku/Sonnet/Opus)
- Efficiency patterns (progressive loading, batching, specificity)
- Weekly review protocol for continuous improvement

### Cost-Optimal Routing (`cost-optimal-routing.md`)
**Core principle**: The cheapest AI is the AI you don't call. Route through cost tiers.

Key points:
- Tier 0: No model call (use deterministic tools first)
- Tier 1: Cheap model, tiny context (classification, extraction)
- Tier 2: Mid model for structured planning
- Tier 3: Expensive model only for hard reasoning
- Pointer packs instead of context stuffing
- Content-hash caching for repeated operations
- Confidence gates to avoid unnecessary escalation

### Wiring Guide (`wiring-guide.md`)
**Core principle**: Practical guide for connecting lazy loading system components.

Key points:
- How manifest.json connects to everything
- How CLAUDE.md hierarchy wires together (Tier 1 → 2 → 3)
- How router.md triggers context loading
- Step-by-step instructions for wiring new repos
- Pointer patterns (forward, back, cross, governance references)
- Validation checklist and common wiring mistakes

### Context Management (`context-management.md`)
**Core principle**: Proactively manage context to prevent exhaustion while maintaining work continuity.

Key points:
- Thresholds: 50-70% awareness, 70-80% suggest options, 80-90% action required, 90%+ critical
- Handoff document pattern for session continuity
- Options at threshold: continue, compact, handoff, commit & close
- Red flags: same file read 3+ times, context >150k on simple task
- Ledger entry required for context-exhausted sessions

---

## Loading Strategy

### On Session Start
Load these rules as part of Tier 1:
- `lazy-loading.md` - Know how to load context
- `three-tier-system.md` - Know the tier boundaries

### On File Operations
Load when creating/modifying files:
- `directory-contract.md` - Know file classification
- `file-lifecycle.md` - Know the workflow

### On Navigation
Load when exploring/routing:
- `repo-router.md` - Know directory purposes

### On Governance Updates
Load when updating the submodule:
- `submodule-management.md` - Know the version workflow

### On Config Creation/Tooling Suggestions
Load when creating config files or suggesting tooling:
- `project-type-detection.md` - Know which configs are relevant

### On Cost/Efficiency Questions
Load when discussing costs or optimization:
- `cost-optimization.md` - Know tracking requirements and patterns
- `cost-optimal-routing.md` - Know the tiered routing strategy

### On System Setup/Wiring
Load when setting up new repos or debugging context loading:
- `wiring-guide.md` - Know how to connect components

### On Context Pressure
Load when context usage is high or session transitions needed:
- `context-management.md` - Know thresholds, handoff patterns, options

---

## Adding New Rules

When adding a new inference rule:

1. **Create the rule file** in `core/inference-rules/`
2. **Update this README** - Add to catalog table and summaries
3. **Update `core/README.md`** - Add to directory structure and rules table
4. **Update CHANGELOG.md** - Document the addition
5. **Bump VERSION** - Minor version for new rules
6. **Tag and release** - Follow `submodule-management.md` workflow

---

## Global vs Instance Rules

| Scope | Location | Purpose |
|-------|----------|---------|
| **Global** | `.governance/ai/core/inference-rules/` | Apply to ALL repos |
| **Instance** | `.ai/inference/<topic>/INFERENCE.md` | Apply to THIS repo only |

Instance rules can extend or override global rules for repo-specific needs.

---

## Related Documentation

- `../README.md` - Core directory overview
- `../rules/SYSTEM.md` - Fundamental AI behavior
- `../rules/AGENT_CONTRACT.md` - AI responsibilities
- `../../00_INDEX/README.md` - Entry point and routing
