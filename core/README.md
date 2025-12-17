# DTLR Governance Core

Universal AI governance rules applicable to **all** DTLR repositories (IaC, applications, data pipelines, etc.).

## Purpose

This repository contains:
- Universal lazy-loading inference rules
- Git workflow standards
- Commit message conventions
- Issue tracking patterns
- Base CLAUDE.md/AGENTS.md templates

## Usage

Add as a submodule to any DTLR repository:

```bash
git submodule add https://github.com/dtlr/governance-core.git .governance/core
```

## Version

Current version: v1.0.0

See [CHANGELOG.md](CHANGELOG.md) for version history.

## Repositories Using This

- tf-msvcs
- tf-network
- web-api
- data-pipeline
- (Add your repo here)

## Autonomous Micro-Batch Mode

AI agents MUST automatically break work into micro-batches to prevent UI stalls:

**Constraints**:
- Max 2 file writes per batch
- Max 120 lines of chat output per batch
- NEVER use parallel execution (sequential only)
- NEVER dump long markdown into chat; write to files instead

**Protocol**:
1. Execute current micro-batch (≤2 files)
2. If work remains: Write NEXT_BATCH.md (do NOT ask user)
3. Print CHECKPOINT (short summary)
4. Await user confirmation before next batch

**Example Flow**:
```
BATCH 1: Create file A, modify file B
→ Print CHECKPOINT
→ Write NEXT_BATCH.md

BATCH 2: Create file C, modify file D
→ Print CHECKPOINT
→ Write NEXT_BATCH.md

BATCH 3: Commit changes
→ Print CHECKPOINT
→ DONE
```

## Contributing

Changes to this repository affect ALL DTLR projects. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on:
- Proposing changes
- Testing across multiple repos
- Version release process
