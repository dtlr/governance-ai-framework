# Submodule Management - AI Operations Guide

**How AI assistants manage governance submodule changes, versioning, and installation.**

This document provides step-by-step procedures for AI to safely modify the governance framework and propagate changes to consuming repositories.

---

## Overview

The governance framework uses a **git submodule architecture**:

```
consuming-repo/
├── .governance/                  # Wrapper directory (repo-owned)
│   └── ai/                       # SUBMODULE → governance-ai-framework
│       └── (framework contents)
```

**Key constraint**: The submodule is **read-only** from the consuming repo's perspective. To make changes, AI must work directly in the framework repository.

---

## Workflow Summary

```
┌─────────────────────────────────────────────────────────────────┐
│  1. VALIDATE CURRENT STATE                                       │
│     - Check submodule version in consuming repo                 │
│     - Identify what changes are needed                          │
└─────────────────────────────────┬───────────────────────────────┘
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│  2. MODIFY FRAMEWORK REPO                                        │
│     - Work in governance-ai-framework repo                       │
│     - Make changes, commit with conventional commit format       │
│     - Create PR and get it merged                                │
└─────────────────────────────────┬───────────────────────────────┘
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│  3. VERSION AND TAG                                              │
│     - Update VERSION file (semantic versioning)                  │
│     - Update CHANGELOG.md                                        │
│     - Create and push git tag                                    │
└─────────────────────────────────┬───────────────────────────────┘
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│  4. UPDATE CONSUMING REPOS                                       │
│     - Fetch new tags with --force                                │
│     - Checkout specific version                                  │
│     - Stage and commit submodule pointer                         │
└─────────────────────────────────┬───────────────────────────────┘
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│  5. VALIDATE INSTALLATION                                        │
│     - Run validation commands                                    │
│     - Confirm correct version is installed                       │
└─────────────────────────────────────────────────────────────────┘
```

---

## Step 1: Validate Current State

### Check Submodule Version in Consuming Repo

**ALWAYS run these commands first** to understand current state:

```bash
# From consuming repo root (e.g., tf-msvcs)
cd /path/to/consuming-repo

# Check what version is currently installed
git -C .governance/ai describe --tags --always

# Check if submodule is initialized
git submodule status .governance/ai

# Verify submodule URL
git config --file .gitmodules submodule..governance/ai.url
```

**Expected output example:**
```
v1.1.0                                    # Current version tag
 64665d7... .governance/ai (v1.1.0)      # Submodule status (commit + tag)
git@github.com:dtlr/governance-ai-framework.git  # SSH URL
```

### Validation Script (if available)

Some repos provide a validation script:
```bash
./scripts/update_governance.sh --status
```

---

## Step 2: Modify Framework Repository

### Navigate to Framework Repo

```bash
# Option A: If repo exists one directory up
cd /path/to/governance-ai-framework

# Option B: Clone fresh
git clone git@github.com:dtlr/governance-ai-framework.git
cd governance-ai-framework
```

### Make Changes

1. **Create branch** (for PRs):
   ```bash
   git checkout -b feat/description-of-change
   ```

2. **Make changes** to appropriate files:
   - `core/inference-rules/` - Behavioral rules for AI
   - `core/templates/` - Reusable templates
   - `core/rules/` - Core system rules
   - `iac/` or `terraform/` - Layer-specific conventions

3. **Commit with conventional format**:
   ```bash
   git add .
   git commit -m "feat(core): Add new inference rule for X"
   ```

4. **Push and create PR**:
   ```bash
   git push -u origin feat/description-of-change
   gh pr create --title "feat(core): Add new inference rule for X" --body "Description..."
   ```

5. **After PR is merged**, pull main:
   ```bash
   git checkout main
   git pull origin main
   ```

---

## Step 3: Version and Tag

### Semantic Versioning Rules

| Change Type | Version Bump | Example |
|-------------|--------------|---------|
| Bug fix, typo | PATCH (1.0.0 → 1.0.1) | Fix typo in SYSTEM.md |
| New feature, template | MINOR (1.0.0 → 1.1.0) | Add golden-image template |
| Breaking change | MAJOR (1.0.0 → 2.0.0) | Rename entrypoint directory |

### Update VERSION File

**CRITICAL**: The VERSION file MUST be updated before tagging.

```bash
# Check current version
cat VERSION

# Edit VERSION file (increment appropriately)
echo "1.2.0" > VERSION

# Commit the version change
git add VERSION
git commit -m "chore: Bump version to 1.2.0"
```

### Update CHANGELOG.md

Add entry at top of file:
```markdown
## [1.2.0] - YYYY-MM-DD

### Added
- New golden-image template for repo bootstrapping
- Submodule management inference rule

### Changed
- Updated CONTRIBUTING.md with clearer instructions
```

Commit:
```bash
git add CHANGELOG.md
git commit -m "docs: Update CHANGELOG for v1.2.0"
```

### Push Commits

```bash
git push origin main
```

### Create and Push Tag

**IMPORTANT**: Tag AFTER pushing the VERSION file update.

```bash
# Create annotated tag
git tag -a v1.2.0 -m "Release v1.2.0"

# Push tag to remote
git push origin v1.2.0
```

### If Tag Already Exists (Error Recovery)

If you get "tag already exists" error:

```bash
# Delete local tag
git tag -d v1.2.0

# Delete remote tag
git push origin :refs/tags/v1.2.0

# Re-create tag on correct commit
git tag -a v1.2.0 -m "Release v1.2.0"

# Push tag
git push origin v1.2.0
```

---

## Step 4: Update Consuming Repos

### Navigate to Consuming Repo

```bash
cd /path/to/consuming-repo
```

### Fetch New Tags

**CRITICAL**: Use `--force` to handle re-tagged versions:

```bash
git -C .governance/ai fetch origin --tags --force
```

Without `--force`, you may see:
```
[rejected] v1.2.0 -> v1.2.0 (would clobber existing tag)
```

### Checkout Specific Version

```bash
# Checkout the new version tag
git -C .governance/ai checkout v1.2.0
```

### Stage and Commit Submodule Update

```bash
# Stage the submodule pointer change
git add .governance/ai

# Commit with descriptive message
git commit -m "chore(governance): Update AI governance submodule to v1.2.0"

# Push to remote
git push origin main
```

---

## Step 5: Validate Installation

### Required Validation Commands

Run ALL of these after updating:

```bash
# 1. Confirm correct version
git -C .governance/ai describe --tags --always
# Expected: v1.2.0

# 2. Confirm VERSION file matches tag
cat .governance/ai/VERSION
# Expected: 1.2.0

# 3. Confirm submodule status is clean
git submodule status .governance/ai
# Expected: starts with space (not - or +)
#  64665d7... .governance/ai (v1.2.0)

# 4. Verify key files exist
ls .governance/ai/00_INDEX/README.md
ls .governance/ai/core/rules/SYSTEM.md
# Expected: files exist, no errors
```

### Validation Output Template

When reporting to user, provide this summary:

```
Submodule Validation:
---------------------
Version Tag:     v1.2.0
VERSION File:    1.2.0 (matches)
Commit:          64665d7
Status:          Clean (initialized)
Remote URL:      git@github.com:dtlr/governance-ai-framework.git
```

### If Validation Fails

| Symptom | Cause | Fix |
|---------|-------|-----|
| Version tag not found | Tag not fetched | `git -C .governance/ai fetch origin --tags --force` |
| VERSION mismatch tag | VERSION not updated before tagging | Re-tag in framework repo |
| Status shows `-` prefix | Submodule not initialized | `git submodule update --init .governance/ai` |
| Status shows `+` prefix | Local changes in submodule | `git -C .governance/ai checkout v1.2.0` |

---

## Common Operations

### Check Available Versions

```bash
git -C .governance/ai tag --list
```

### Rollback to Previous Version

```bash
git -C .governance/ai checkout v1.1.0
git add .governance/ai
git commit -m "chore(governance): Rollback to v1.1.0"
```

### Re-initialize Broken Submodule

```bash
# Remove corrupted submodule
rm -rf .governance/ai

# Re-initialize
git submodule update --init --force .governance/ai

# Checkout desired version
git -C .governance/ai checkout v1.2.0
```

---

## Safety Rules

### NEVER Do

- **NEVER** modify files directly in `.governance/ai/` from consuming repo
- **NEVER** commit with submodule in detached HEAD on untagged commit
- **NEVER** skip the VERSION file update before tagging
- **NEVER** push tags without pushing commits first

### ALWAYS Do

- **ALWAYS** use `git -C .governance/ai` to operate on submodule (avoid `cd`)
- **ALWAYS** use `--force` when fetching tags (handles re-tags)
- **ALWAYS** validate installation after updating
- **ALWAYS** use annotated tags (`git tag -a`)
- **ALWAYS** match VERSION file content to tag name (1.2.0 for v1.2.0)

---

## Related Documentation

- `CONTRIBUTING.md` - Detailed contribution guidelines
- `CHANGELOG.md` - Version history and changes
- `VERSION` - Current version number
- `core/inference-rules/directory-contract.md` - File classification rules
