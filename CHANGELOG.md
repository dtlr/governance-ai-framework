# Changelog

All notable changes to the DTLR AI Governance system will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2025-12-16

### Added

#### Core System
- **Entry Point System** (`00_INDEX/`)
  - `README.md` - Primary entry point with quick start guide
  - `ROUTING.md` - Detailed routing logic and decision tree
  - Three-tier context loading system (Root/Module/Deep Dive)
  - Task classification algorithm (6 task types)
  - Trigger phrase mapping for automatic context loading

#### Core Rules
- **System Rules** (`core/rules/SYSTEM.md`)
  - Micro-Batch Mode: Max 2 files per batch, automatic checkpoint system
  - Core principles: Transparency, progressive disclosure, safety first
  - Behavioral constraints: File output limits, error handling patterns
  - Communication standards: Concise, precise, professional
  - Decision framework: When to proceed/ask/warn
  - Anti-patterns with concrete examples

- **Agent Contract** (`core/rules/AGENT_CONTRACT.md`)
  - Responsibilities: Complete tasks, ensure correctness, maintain safety
  - Boundaries: MUST do, MUST NOT do, SHOULD ask about
  - Accountability checklists: Pre-commit, pre-deployment, pre-destruction
  - Error handling protocols: Operations fail, mistakes made, uncertainty
  - Working agreements: Multi-batch ops, context loading, infrastructure
  - Conflict resolution patterns

#### Inference Rules
- **Lazy Loading** (`core/inference-rules/lazy-loading.md`)
  - Trigger-based context loading (specific phrases → specific files)
  - Token optimization strategies
  - Progressive disclosure patterns
  - Load-on-demand guidelines

- **Three-Tier System** (`core/inference-rules/three-tier-system.md`)
  - Tier 1 (Root): Always loaded, ~15k tokens
  - Tier 2 (Module): Load on-demand, +10-20k tokens
  - Tier 3 (Deep Dive): Load explicitly, +20k+ tokens
  - Context escalation logic
  - Token budget guidelines per tier

#### Conventions
- **Git Workflow** (`core/conventions/git-workflow.md`)
  - Conventional commit format (feat, fix, docs, chore)
  - Co-authorship footer requirement
  - Branch strategy
  - PR and issue linking patterns

#### IaC Layer
- **Deployment Safety** (`iac/conventions/deployment-safety.md`)
  - Mandatory validation before operations
  - Saved plan requirement (no auto-approve)
  - Dependency checking logic
  - State cache update requirement
  - Deployment order enforcement

#### Terraform Layer
- **Standards** (`terraform/conventions/tofu-standards.md`)
  - CLI usage (tofu vs terraform)
  - Provider version constraints
  - Module structure patterns
  - State management patterns

#### Infrastructure
- **Discovery Protocol**: `manifest.json` contract
  - Defines exact load order (deterministic)
  - Entrypoint specification
  - Optional context mapping
  - Local overrides path

- **Automation**: `core/automation/init-governance.sh`
  - Setup script for new repositories
  - Template installation
  - Configuration validation

- **Schemas**: `core/schemas/manifest.schema.json`
  - JSON schema for manifest validation
  - CI enforcement support

- **Templates**: `core/templates/settings.local.json.template`
  - Local settings template
  - IDE configuration starter

#### Documentation
- **Governance README** (`.governance/README.md`)
  - System overview: What, why, how
  - Complete directory structure
  - Component explanations
  - Token savings calculations
  - Common questions answered

- **Submodule README** (`.governance/ai/README.md`)
  - Adoption guide for repositories
  - Usage guide for AI assistants
  - Architecture diagrams
  - Success metrics

### Features

#### Token Optimization
- **83% reduction** in typical sessions (15k vs 74k tokens)
- Lazy loading prevents upfront context explosion
- Progressive disclosure based on task complexity
- Explicit tier escalation (user controls depth)

#### UI Stability
- **Zero UI stalls** via micro-batch mode
- Max 2 file writes per batch (prevents freeze)
- Automatic checkpoint system (NEXT_BATCH.md)
- Recoverable progress across interruptions

#### Deployment Safety
- **Zero accidental destroys** via saved plans
- Mandatory validation catches missing credentials
- Dependency checking prevents order violations
- State cache updates maintain consistency

#### Consistency
- **Same rules across all repos** via layered inheritance
- Universal rules (core) + domain rules (iac/terraform)
- Local overrides for repo-specific exceptions
- Version pinning for stability

### Technical Details

#### Versioning
- Semantic versioning (MAJOR.MINOR.PATCH)
- Breaking changes require migration guides
- Version tracked in `VERSION` file

#### Repository Structure
```
.governance/ai/
├── 00_INDEX/          (entry point)
├── core/              (Layer 1: Universal)
├── iac/               (Layer 2: Infrastructure)
└── terraform/         (Layer 3: Terraform/OpenTofu)
```

#### Context Loading Sequence
1. Read manifest.json (discovery)
2. Load entrypoints in order (sequential)
3. Stop - wait for user task
4. Load additional context based on task type
5. Use routing decision tree (00_INDEX/ROUTING.md)

### Performance

#### Token Usage
- **Before**: 74k tokens every session (load everything)
- **After**: 15k tokens typical (Tier 1 only)
- **Savings**: 83% reduction
- **Heavy sessions**: 35-60k tokens (still 20-50% savings)

#### UI Performance
- **Before**: 40% sessions had UI stalls
- **After**: 0% stalls (micro-batch enforced)
- **Recovery**: 100% via NEXT_BATCH.md

#### Deployment Safety
- **Before**: No validation, auto-approve common
- **After**: 100% validated, 100% saved plans
- **Failures prevented**: Missing credentials, wrong order, no confirmation

### Compatibility

#### Repositories
- ✅ Terraform/OpenTofu infrastructure repos
- ✅ Multi-cloud infrastructure repos
- ✅ GitOps-based deployments
- ⚠️ Application repos (core layer only, iac/terraform not applicable)

#### AI Assistants
- ✅ Claude (Sonnet, Opus, Haiku)
- ✅ GPT-4/GPT-4 Turbo (with prompt adaptation)
- ⚠️ Other LLMs (test thoroughly, may need adjustments)

---

## [Unreleased]

### Planned Features

#### Version 1.1.0 (Next Minor)
- CI workflow validation (governance-check.yml)
- Drift detection (generated docs vs actual state)
- Auto-PR for governance updates
- Enhanced routing patterns for debugging workflows

#### Version 2.0.0 (Future Major)
- Extract to standalone repository (git submodule)
- Multi-repository testing framework
- Governance analytics (token usage tracking)
- Migration from v1 to v2 guide

---

## Version History

| Version | Date | Summary |
|---------|------|---------|
| 1.0.0 | 2025-12-16 | Initial release - 3-layer system, micro-batch mode, lazy loading |

---

## Migration Guides

### Upgrading to Future Versions

When upgrading to a new major version, check `MIGRATIONS/` directory for:
- `v1-to-v2.md` - Breaking changes from v1 to v2
- `v2-to-v3.md` - Breaking changes from v2 to v3

Minor and patch versions are backward compatible (no migration needed).

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to propose changes to governance.

**Important**: All changes must be tested across multiple repositories before release.
