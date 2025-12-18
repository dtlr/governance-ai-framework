# DTLR AI Governance

**Unified governance system for AI assistants across all DTLR repositories**

Version: 1.4.0


## What This Is

A **structured ruleset** that guides AI assistants (Claude, GPT, etc.) working in DTLR codebases. Prevents common AI failures like context overload, UI stalls, inconsistent workflows, and unsafe operations.


## Why This Exists

### Problems Solved
- **Context explosion**: AI loads 60k+ tokens upfront → slow responses
- **UI stalls**: AI writes 8+ files in parallel → freezes Cursor/VSCode
- **Inconsistency**: Each repo has different rules → unpredictable behavior
- **No recovery**: AI gets interrupted → all progress lost
- **Unsafe operations**: AI auto-approves `tofu destroy` → production disaster

### Solution
- **Lazy loading**: Load only what's needed (75% token reduction)
- **Micro-batch mode**: Max 2 files per batch, checkpoints, recoverable
- **3-layer system**: Universal rules + Infrastructure rules + Repo-specific config
- **Deployment safety**: Validation, saved plans, dependency checks
- **Discovery protocol**: Manifest defines exact load order


## Architecture

### Three Layers (Inheritance)

```
┌─────────────────────────────────────────────────────────────┐
│ Layer 1: CORE (Universal - ALL repos)                      │
├─────────────────────────────────────────────────────────────┤
│ • Micro-Batch Mode (prevents UI stalls)                    │
│ • Lazy Loading (token optimization)                        │
│ • Three-Tier System (progressive disclosure)               │
│ • Git Workflow (conventional commits)                      │
│ • Agent Contract (responsibilities, boundaries)            │
└─────────────────────────────────────────────────────────────┘
         ↓ + Infrastructure-specific rules
┌─────────────────────────────────────────────────────────────┐
│ Layer 2: IaC (Infrastructure-as-Code repos)                │
├─────────────────────────────────────────────────────────────┤
│ • Deployment Safety (saved plans, validation)              │
│ • State Management (cache updates, backend config)         │
│ • Script Patterns (safe module execution)                  │
└─────────────────────────────────────────────────────────────┘
         ↓ + Terraform-specific rules
┌─────────────────────────────────────────────────────────────┐
│ Layer 3: TERRAFORM (OpenTofu/Terraform repos)              │
├─────────────────────────────────────────────────────────────┤
│ • CLI Standards (tofu vs terraform)                        │
│ • Provider Constraints (version management)                │
│ • Module Dependencies (deployment order)                   │
└─────────────────────────────────────────────────────────────┘
```

Each layer **inherits** from previous layers (additive, not replacement).


## Directory Structure

```
.governance/ai/                        ← This submodule
├── VERSION                            ← Semantic versioning (1.0.0)
├── README.md                          ← This file
├── CHANGELOG.md                       ← Version history
├── CONTRIBUTING.md                    ← How to propose changes
│
├── 00_INDEX/                          ← Entry point (AI starts here)
│   ├── README.md                      ← Quick start, routing logic
│   └── ROUTING.md                     ← Decision tree (task → context)
│
├── core/                              ← Layer 1: Universal rules
│   ├── README.md                      ← Core overview
│   ├── rules/
│   │   ├── SYSTEM.md                  ← Fundamental behavioral rules
│   │   └── AGENT_CONTRACT.md          ← AI responsibilities & boundaries
│   ├── inference-rules/
│   │   ├── README.md                  ← Index of all inference rules
│   │   ├── lazy-loading.md            ← When to load context (triggers)
│   │   ├── three-tier-system.md       ← Context tiers (root/module/deep)
│   │   ├── directory-contract.md      ← A/B/C file classification
│   │   ├── file-lifecycle.md          ← Create/update/delete workflow
│   │   ├── repo-router.md             ← Directory→purpose mapping
│   │   └── submodule-management.md    ← Governance version updates
│   ├── conventions/
│   │   └── git-workflow.md            ← Commit standards, co-authorship
│   ├── automation/
│   │   └── init-governance.sh         ← Setup script for new repos
│   ├── schemas/
│   │   └── manifest.schema.json       ← JSON schema for manifest.json
│   └── templates/
│       ├── golden-image/              ← Complete repo bootstrap template
│       └── settings.local.json.template
│
├── iac/                               ← Layer 2: Infrastructure repos
│   ├── README.md                      ← IaC layer overview
│   └── conventions/
│       └── deployment-safety.md       ← Saved plans, validation, order
│
└── terraform/                         ← Layer 3: Terraform/OpenTofu repos
    ├── README.md                      ← Terraform layer overview
    └── conventions/
        └── tofu-standards.md          ← CLI usage, provider constraints
```


## How It Works

### On Session Start

1. AI reads `.governance/manifest.json` (discovery contract)
2. Loads entrypoints in order:
   - `00_INDEX/README.md` (entry point)
   - `core/rules/SYSTEM.md` (behavioral rules)
   - `core/rules/AGENT_CONTRACT.md` (responsibilities)
   - Layer-specific rules (iac, terraform if applicable)
3. Reads repo-specific config (`.governance-local/overrides.yaml`)
4. **STOPS** - waits for user task

**Tokens loaded**: ~15k (root tier only)


### During Work

AI loads additional context based on task type:

| User Says | Tier | Load | Tokens |
|-----------|------|------|--------|
| "Fix typo in README" | 1 | Root context only | ~15k |
| "Deploy module 3" | 2 | Module context + safety rules | ~25k |
| "Show all infrastructure" | 3 | Full state + all modules | ~60k |

**Result**: 75% token reduction vs loading everything upfront


### Key Rules

#### Micro-Batch Mode (Anti-Stall)
- Max 2 file writes per batch
- Write `NEXT_BATCH.md` after batch if work remains
- Checkpoint after each batch
- Sequential execution (never parallel)

#### Lazy Loading (Token Optimization)
- Load minimum context needed
- Use trigger phrases to load more
- Stay in Tier 1 unless task requires more

#### Deployment Safety (Infrastructure)
- Validate environment first
- Generate saved plan (`tofu plan -out=tofu.plan`)
- User reviews plan
- Apply saved plan (never auto-approve)
- Update state cache


## Usage

### For Repository Maintainers

#### Add to Existing Repo
```bash
# Copy governance structure
cp -r /path/to/governance/ai .governance/ai

# Create local config
cp .governance/ai/core/templates/overrides.yaml.template .governance-local/overrides.yaml

# Edit overrides for your repo
vi .governance-local/overrides.yaml

# Create manifest
cat > .governance/manifest.json <<EOF
{
  "version": "1.0.0",
  "governance_root": ".governance/ai",
  "entrypoints": [
    "00_INDEX/README.md",
    "core/rules/SYSTEM.md",
    "core/rules/AGENT_CONTRACT.md"
  ],
  "local_overrides": ".governance-local/overrides.yaml"
}
EOF

# Commit
git add .governance/ .governance-local/
git commit -m "feat: Add AI governance system"
```

#### Use as Git Submodule (Future)
```bash
# When governance is extracted to separate repo
git submodule add https://github.com/dtlr/ai-governance .governance/ai
git submodule update --init

# Pin to specific version
cd .governance/ai
git checkout v1.3.0
cd ../..
git add .governance/ai
git commit -m "feat: Add governance submodule at v1.3.0"
```


### For AI Assistants

When working in a DTLR repository:

1. **Check for governance**: Look for `.governance/manifest.json`
2. **Load entrypoints**: Read files listed in manifest
3. **Follow rules**: SYSTEM.md (behavior) + AGENT_CONTRACT.md (responsibilities)
4. **Load on-demand**: Use routing logic in `00_INDEX/ROUTING.md`
5. **Respect constraints**: Micro-batch mode, lazy loading, deployment safety


## Token Savings

### Before Governance (Old Way)
```
Load everything upfront:
- Root CLAUDE.md: 3k tokens
- All module CLAUDE.md files: 56k tokens
- STATE_CACHE.md: 15k tokens
TOTAL: 74k tokens every session
```

### After Governance (New Way)
```
Typical session (Tier 1 + Tier 2):
- Root context: 5k tokens
- One module context: 4k tokens
- IaC rules: 3k tokens
TOTAL: 12k tokens
SAVINGS: 83% reduction
```


## Versioning

### Current Version: 1.4.0

**Breaking Changes**: Major version bump (e.g., 2.0.0)
- Require migration guide in `MIGRATIONS/`
- Repos pin to specific version
- Test across multiple repos before release

**New Features**: Minor version bump (e.g., 1.1.0)
- Backward compatible
- No migration needed
- Repos can upgrade anytime

**Bug Fixes**: Patch version bump (e.g., 1.0.1)
- Zero breaking changes
- Safe to upgrade immediately


## Repositories Using This

- **tf-msvcs** - Multi-cloud infrastructure (DigitalOcean, Azure, Cloudflare)
- _(Add your repo here when you adopt governance)_


## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for:
- How to propose changes
- Testing requirements (test across multiple repos)
- Version release process
- Breaking change guidelines

**Important**: Changes to this governance system affect **all** DTLR repositories. Test thoroughly before merging.


## Documentation

### Quick Reference
- **Entry Point**: `00_INDEX/README.md`
- **Behavioral Rules**: `core/rules/SYSTEM.md`
- **Responsibilities**: `core/rules/AGENT_CONTRACT.md`
- **Routing Logic**: `00_INDEX/ROUTING.md`

### Deep Dive
- **Inference Rules Index**: `core/inference-rules/README.md`
- **Lazy Loading**: `core/inference-rules/lazy-loading.md`
- **Three-Tier System**: `core/inference-rules/three-tier-system.md`
- **Directory Contract**: `core/inference-rules/directory-contract.md`
- **File Lifecycle**: `core/inference-rules/file-lifecycle.md`
- **Repo Router**: `core/inference-rules/repo-router.md`
- **Submodule Management**: `core/inference-rules/submodule-management.md`
- **Git Workflow**: `core/conventions/git-workflow.md`
- **Deployment Safety**: `iac/conventions/deployment-safety.md`
- **Terraform Standards**: `terraform/conventions/tofu-standards.md`
- **Golden Image Template**: `core/templates/golden-image/README.md`


## Support

- **Issues**: File issues in the repository where governance is used
- **Questions**: Open discussion in #infrastructure channel
- **Proposals**: Create PR with changes + rationale


## License

Internal use within DTLR organization only.


## Success Metrics

### Target
- Average context load: 15k tokens (vs 60k before)
- UI stalls: 0% (vs 40% before)
- Deployment failures: <5% (with proper validation)
- Recovery rate: 100% (NEXT_BATCH.md enables full recovery)

### Actual (As of v1.0.0)
- Deployed in: 1 repository (tf-msvcs)
- Token reduction: 83% in typical sessions
- UI stalls: 0% (micro-batch mode enforced)
- Recovery: Full recovery enabled via NEXT_BATCH.md


**For full context**: See parent `.governance/README.md` in the repository using this governance system.
