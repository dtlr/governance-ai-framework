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
