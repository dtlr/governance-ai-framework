# Governance Entry Point

**You are here**: `.governance/ai/00_INDEX/README.md`

This is the **primary entry point** for AI assistants working in this repository. Read this file first.


## Quick Start: What to Load

### On Session Start (ALWAYS)
Load these 5 files in order (from `.governance/manifest.json` entrypoints):

1. **This file** - Entry point and routing logic
2. `.governance/ai/core/rules/SYSTEM.md` - Fundamental behavioral rules
3. `.governance/ai/core/rules/AGENT_CONTRACT.md` - AI responsibilities
4. `.governance/ai/iac/conventions/deployment-safety.md` - Infrastructure safety rules
5. `.governance/ai/terraform/README.md` - Terraform/OpenTofu standards

**Result**: You now understand how to behave, what context to load, and how to safely work with infrastructure code


## Context Caching Instructions (For AI Clients with Prompt Caching)

If your client supports prompt caching (e.g., Claude API with `cache_control`), use these cache blocks to reduce repeated token loading:

**Cache Block 1: Governance Rules** (~8k tokens, stable across sessions)
- `.governance/ai/core/rules/SYSTEM.md`
- `.governance/ai/core/rules/AGENT_CONTRACT.md`
- `.governance/ai/core/validation/INVARIANTS.md`
- `.governance/ai/iac/conventions/deployment-safety.md`
- `.governance/ai/terraform/conventions/tofu-standards.md`

**Cache invalidation**: Only on governance version bump (v1.0.0 → v1.1.0)

**Cache Block 2: Repository Context** (~2k tokens, changes per apply)
- `CLAUDE.md` (root) - Repository overview
- `.governance-local/overrides.yaml` - Repo-specific config
- **DO NOT CACHE**: `STATE_CACHE*.md` (updates after every terraform apply)

**Cache TTL**: 5 minutes (extends on use), expires faster for files that change frequently

**Expected savings**: 50-70% reduction in token loading for sessions within 5-minute windows


### Based on User Task (ON-DEMAND)
Load additional context based on what the user asks for:

| User Says | Load Context |
|-----------|--------------|
| "Work on module X" | `X/CLAUDE.md` (module-specific context) |
| "Show me state" | `STATE_CACHE_QUICK.md` (critical resources only, Tier 1) |
| "Explain deployment order" | `.governance-local/overrides.yaml` |
| "Show me all resources" | `STATE_CACHE_FULL.md` + module CLAUDE.md files (Tier 2+) |
| "Troubleshoot" | `docs/_shared/troubleshooting.md` |
| "What changed recently?" | `STATE_CACHE_DIFF.md` (last 5 applies) |

**Result**: You load only what's needed for the current task


## The Three Tiers (Progressive Disclosure)

### Tier 1: Root Context (ALWAYS LOADED)
**When**: Every session
**What**: Repository overview, structure, core rules
**Files**:
- `CLAUDE.md` (root) - Repo overview
- `.governance/manifest.json` - Discovery contract
- `.governance/ai/00_INDEX/README.md` - This file
- `.governance/ai/core/rules/*.md` - Behavioral rules
- Layer files (iac, terraform conventions)
- `STATE_CACHE_QUICK.md` - Critical resources only (clusters, databases, networks)

**Token Budget**: ~10k tokens (measured with tiktoken)
**Use For**: Simple tasks (typo fixes, file reads, basic operations)


### Tier 2: Module Context (LOAD ON-DEMAND)
**When**: User mentions specific module or you need module details
**What**: Module-specific operations, dependencies, credentials
**Files**:
- `<module>/CLAUDE.md` - Module AI context
- `<module>/AGENTS.md` - Module operations guide
- Related sections from overrides.yaml

**Token Budget**: +10-20k tokens (~25-35k total, typical)
**Use For**: Module deployments, debugging, modifications


### Tier 3: Deep Dive (LOAD EXPLICITLY)
**When**: User explicitly requests ("show me all", "explain everything")
**What**: Full system knowledge, complete state, detailed guides
**Files**:
- `STATE_CACHE_FULL.md` - Complete terraform state (all modules, all resources)
- `docs/_shared/*.md` - Troubleshooting, security, credentials
- All module CLAUDE.md files
- Architecture diagrams

**Token Budget**: +20k+ tokens (~45-60k total when fully loaded)
**Use For**: Architecture reviews, full system analysis, troubleshooting

**Note**: Token counts are illustrative examples, not guarantees. Actual numbers vary with model tokenizer and content changes. The invariant is scope-based loading (root/module/deep), not specific numbers.


## Loading Decision Tree

```
START: New session begins
│
├─→ Read Tier 1 (ALWAYS)
│   ├─ .governance/ai/00_INDEX/README.md
│   ├─ .governance/ai/core/rules/SYSTEM.md
│   ├─ .governance/ai/core/rules/AGENT_CONTRACT.md
│   ├─ .governance/ai/iac/conventions/deployment-safety.md
│   └─ .governance/ai/terraform/conventions/tofu-standards.md
│
├─→ Read repo-specific config
│   ├─ CLAUDE.md (root)
│   └─ .governance-local/overrides.yaml
│
└─→ STOP - Wait for user task
    │
    ├─→ USER: "Fix typo in README"
    │   └─→ Stay in Tier 1 (no additional loading)
    │
    ├─→ USER: "Deploy module 3"
    │   ├─→ Load Tier 2 (module context)
    │   ├─ 3-azure-0/CLAUDE.md
    │   ├─ Check dependencies in overrides.yaml
    │   └─→ Execute deployment workflow
    │
    ├─→ USER: "Show me all Azure resources"
    │   ├─→ Load Tier 3 (deep dive)
    │   ├─ STATE_CACHE.md
    │   ├─ All azure-related module CLAUDE.md files
    │   └─→ Present comprehensive view
    │
    └─→ USER: "Something broke, help debug"
        ├─→ Load Tier 2 + troubleshooting
        ├─ Relevant module CLAUDE.md
        ├─ docs/_shared/troubleshooting.md
        └─→ Follow debug workflow
```


## Routing Rules (When to Load What)

### Trigger Phrases → Context Loading

| Phrase Pattern | Action | Load |
|----------------|--------|------|
| "work on module X" | Load module context | Tier 2 (`X/CLAUDE.md`) |
| "deploy X" | Load module + safety | Tier 2 + deployment-safety.md |
| "show me state" | Load state cache | Tier 3 (`STATE_CACHE.md`) |
| "explain X" where X is module | Load module docs | Tier 2 (`X/CLAUDE.md`, `X/AGENTS.md`) |
| "explain X" where X is concept | Load conceptual docs | Tier 3 (`docs/_shared/`) |
| "all X" (all resources, all modules) | Load comprehensive view | Tier 3 (multiple files) |
| "troubleshoot" | Load debug context | Tier 2/3 (troubleshooting.md) |
| "how do I X" where X is infra task | Load conventions | Tier 1 (deployment-safety.md) |


## Repository-Specific Context

This repository (`tf-msvcs`) is:
- **Type**: Multi-cloud infrastructure-as-code
- **Stack**: OpenTofu (not Terraform)
- **Clouds**: DigitalOcean, Azure, Cloudflare
- **Pattern**: GitOps via ArgoCD

### Key Files (Load Based on Task)
- `CLAUDE.md` - Repo overview, structure, conventions
- `AGENTS.md` - Detailed infrastructure guide
- `STATE_CACHE.md` - Cached state from all modules
- `.governance-local/overrides.yaml` - Module config, deployment order

### Module Structure (14 modules)
**Ordered** (dependencies): 0 → 1 → 3 → 4 → 5 → 7 → 8
**Standalone** (no dependencies): 9-dream, azure-vms, cloudflare*, infra-apps, infra-appsets


## Operating Constraints (MUST FOLLOW)

### Micro-Batch Mode
- **Max 2 file writes per batch**
- **Max 120 lines chat output per batch**
- **NEVER parallel execution** (sequential only)
- **ALWAYS write NEXT_BATCH.md** after batch if work remains

### Deployment Safety (Infrastructure Operations)
- **MUST validate environment** (`./scripts/validate_env.sh`)
- **MUST use saved plans** (`tofu plan -out=tofu.plan`)
- **NEVER auto-approve** (`tofu apply tofu.plan`, not `tofu apply -auto-approve`)
- **MUST update state cache** (`./scripts/update_state_cache.sh` after apply)
- **MUST follow deployment order** (check overrides.yaml)

### Context Discipline
- **Don't load everything upfront** (wastes tokens)
- **Use trigger phrases** to load additional context
- **Stay in Tier 1** unless task requires more
- **Explicitly state what you're loading** (transparency)


## Token Budget Guidelines

**Target**: 80% of sessions stay in Tier 1 or Tier 2 (~15-35k tokens cumulative)

| Session Type | Loaded | Typical Tokens |
|--------------|--------|----------------|
| Good (Tier 1) | Root context only | ~15k |
| Typical (Tier 2) | Root + module context | ~25k |
| Heavy (Tier 3) | Root + module + deep dive | ~60k |

Token counts are illustrative. See `core/inference-rules/three-tier-system.md` for details.


## Common Workflows

### Simple Task (Stay in Tier 1)
```
1. User: "Update the README"
2. Read file
3. Make change
4. Commit
→ No additional context needed
```

### Module Deployment (Tier 1 + Tier 2)
```
1. User: "Deploy module 7"
2. Load: 7-datadog/CLAUDE.md
3. Check: Dependencies in overrides.yaml (modules 1, 5)
4. Validate: ./scripts/validate_env.sh 7-datadog
5. Plan: tofu plan -out=tofu.plan
6. User reviews plan
7. Apply: tofu apply tofu.plan
8. Update cache: ./scripts/update_state_cache.sh
9. Commit with plan output
```

### Architecture Review (Tier 1 + Tier 3)
```
1. User: "Explain the full infrastructure"
2. Load: STATE_CACHE.md
3. Load: docs/architecture/governance-unified.md
4. Load: All module CLAUDE.md files (progressive)
5. Present: High-level → detailed as needed
```


## Error Recovery

If you get interrupted mid-task:
1. Check for `NEXT_BATCH.md` in repo root
2. If exists: Read it to understand incomplete work
3. Resume from checkpoint
4. Continue following micro-batch constraints

If `NEXT_BATCH.md` doesn't exist:
1. Ask user what they were working on
2. Load appropriate tier based on task
3. Proceed from beginning


## For More Information

- **General overview**: `.governance/README.md`
- **Behavioral rules**: `.governance/ai/core/rules/SYSTEM.md`
- **Responsibilities**: `.governance/ai/core/rules/AGENT_CONTRACT.md`
- **Routing details**: `.governance/ai/00_INDEX/ROUTING.md`
- **Architecture**: `docs/architecture/governance-unified.md`


## Summary: Your Starting Checklist

On every new session:
- [ ] Read this file (00_INDEX/README.md)
- [ ] Read SYSTEM.md (core behavioral rules)
- [ ] Read AGENT_CONTRACT.md (your responsibilities)
- [ ] Read deployment-safety.md (infrastructure safety)
- [ ] Read terraform/README.md (terraform conventions)
- [ ] Read CLAUDE.md (repo overview)
- [ ] Read overrides.yaml (module config)
- [ ] Check NEXT_BATCH.md (if exists - resume work)
- [ ] **STOP** - Wait for user task before loading more

**Then**: Load Tier 2 or Tier 3 context based on user's task.
