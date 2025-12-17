# Contributing to DTLR AI Governance

Thank you for contributing to the governance system that guides AI assistants across DTLR repositories.

**Important**: Changes here affect **all** DTLR projects using this governance. Test thoroughly before merging.

---

## Table of Contents

1. [Before You Start](#before-you-start)
2. [Proposing Changes](#proposing-changes)
3. [Testing Requirements](#testing-requirements)
4. [Documentation Standards](#documentation-standards)
5. [Version Management](#version-management)
6. [Review Process](#review-process)

---

## Before You Start

### Understand the Impact

Changes to governance affect:
- **All repositories** using this governance system
- **All AI assistants** working in those repositories
- **All developers** relying on consistent AI behavior

### Identify the Layer

Determine which layer your change belongs to:

| Layer | Scope | Files |
|-------|-------|-------|
| **Core** | Universal (all repos) | `core/` |
| **IaC** | Infrastructure repos only | `iac/` |
| **Terraform** | Terraform/OpenTofu repos | `terraform/` |

**Rule**: Keep changes at the **most specific layer** possible. Don't add terraform-specific rules to core.

---

## Proposing Changes

### Types of Changes

#### 1. Bug Fixes (Patch: 1.0.x)
**Examples**:
- Fix typo in documentation
- Correct broken link
- Fix incorrect example
- Clarify ambiguous wording

**Process**:
1. Create branch: `fix/description`
2. Make minimal change
3. Test in 1+ repos
4. Create PR with "fix:" prefix
5. Bump patch version (1.0.0 → 1.0.1)

---

#### 2. New Features (Minor: 1.x.0)
**Examples**:
- Add new routing pattern
- Add new convention
- Add new template
- Expand documentation

**Process**:
1. Create branch: `feat/description`
2. Add feature (backward compatible)
3. Test in 2+ repos (different types if possible)
4. Update CHANGELOG.md
5. Create PR with "feat:" prefix
6. Bump minor version (1.0.0 → 1.1.0)

---

#### 3. Breaking Changes (Major: x.0.0)
**Examples**:
- Change manifest.json structure
- Rename files/directories
- Remove features
- Change behavior significantly

**Process**:
1. Open discussion issue first (get consensus)
2. Create branch: `feat!/description` or `breaking/description`
3. Implement change
4. **Create migration guide** in `MIGRATIONS/`
5. Test in 3+ repos (prove migration works)
6. Update CHANGELOG.md (Breaking Changes section)
7. Create PR with "feat!:" or "breaking:" prefix
8. Bump major version (1.x.x → 2.0.0)

**Requirements for Breaking Changes**:
- [ ] Discussion issue with approval from 2+ maintainers
- [ ] Migration guide written and tested
- [ ] Tested across 3+ different repos
- [ ] CHANGELOG.md updated with breaking changes section
- [ ] Version bumped to next major

---

## Testing Requirements

### Minimum Testing Standards

| Change Type | Minimum Repos | Types Required | Notes |
|-------------|---------------|----------------|-------|
| Bug fix | 1 | Any | Verify fix works |
| New feature | 2 | Same type OK | Prove feature works |
| Breaking change | 3 | Different types preferred | Prove migration works |

### Recommended Test Repositories

Test across different repo types:

1. **Infrastructure** (tf-msvcs): Multi-cloud, complex dependencies
2. **Application** (web-api): Node.js, application code
3. **Data** (data-pipeline): Python, data processing

### Testing Checklist

For each test repository:

```
□ AI can discover governance (reads manifest.json)
□ AI loads correct entrypoints (in correct order)
□ AI follows micro-batch mode (≤2 files per batch)
□ AI loads context efficiently (not everything upfront)
□ AI respects safety rules (validation, saved plans)
□ No errors in governance loading
□ No contradictions between layers
□ Token usage reasonable (<20k for typical tasks)
```

### Testing Procedure

1. **Start fresh session** in test repo
2. **Give test task**: "Deploy module X" or similar
3. **Observe AI behavior**:
   - Does it load correct context?
   - Does it follow micro-batch mode?
   - Does it validate before operations?
   - Does it use saved plans?
4. **Verify results**:
   - Task completed correctly
   - No violations of governance rules
   - Token usage efficient
5. **Document results** in PR

---

## Documentation Standards

### File Format

All governance files use **Markdown** (.md):
- Clear headings (H1 for title, H2 for sections, H3 for subsections)
- Code blocks with language tags (```bash, ```json, etc.)
- Tables for comparisons
- Examples marked with ✅ GOOD / ❌ BAD

### Writing Style

**Be Clear**:
- Short paragraphs (2-4 sentences)
- Simple language (avoid jargon unless necessary)
- Concrete examples (not abstract concepts)

**Be Specific**:
- "Run `tofu plan -out=tofu.plan`" not "generate a plan"
- "Load module CLAUDE.md" not "load module context"
- "Max 2 file writes per batch" not "write files in batches"

**Be Actionable**:
- Tell AI what to do, not what to think about
- Provide specific commands, not suggestions
- Use imperative voice ("Load X" not "You should load X")

### Documentation Structure

Each major file should have:

```markdown
# Title

**Brief description** (1-2 sentences)

---

## Table of Contents (if >5 sections)

---

## Section 1

Content with examples

---

## Section 2

Content with examples

---

## Related Documentation

- Link to related files
```

---

## Version Management

### Semantic Versioning

We follow [Semantic Versioning 2.0.0](https://semver.org/):

```
MAJOR.MINOR.PATCH

1.2.3
│ │ │
│ │ └─ Patch: Bug fixes, no breaking changes
│ └─── Minor: New features, backward compatible
└───── Major: Breaking changes, requires migration
```

### When to Bump Version

| Change | Version Bump | Example |
|--------|--------------|---------|
| Fix typo | Patch (1.0.0 → 1.0.1) | Fix typo in SYSTEM.md |
| Add routing pattern | Minor (1.0.0 → 1.1.0) | Add debug workflow routing |
| Rename entrypoint | Major (1.0.0 → 2.0.0) | Change 00_INDEX/ to INDEX/ |

### How to Bump Version

1. **Edit VERSION file**: Update version number
2. **Edit CHANGELOG.md**: Add entry under appropriate version
3. **Commit**: `chore: Bump version to X.Y.Z`
4. **Tag** (after merge): `git tag vX.Y.Z`

---

## Review Process

### Pull Request Template

```markdown
## Change Type
- [ ] Bug fix (patch)
- [ ] New feature (minor)
- [ ] Breaking change (major)

## Description
Brief description of change

## Layer
- [ ] Core (universal)
- [ ] IaC (infrastructure)
- [ ] Terraform (terraform/opentofu)

## Testing
- [ ] Tested in repo: X
- [ ] Tested in repo: Y
- [ ] Tested in repo: Z (if breaking change)

## Checklist
- [ ] CHANGELOG.md updated
- [ ] VERSION file updated (if applicable)
- [ ] Migration guide written (if breaking change)
- [ ] Documentation follows standards
- [ ] Examples are clear and correct

## Test Results
Describe what you tested and results
```

### Review Criteria

Reviewers check:

**Technical**:
- [ ] Change is in correct layer (core/iac/terraform)
- [ ] No contradictions with existing rules
- [ ] No over-engineering (simplest solution that works)
- [ ] Proper version bump

**Documentation**:
- [ ] Clear, specific, actionable
- [ ] Examples are correct
- [ ] No typos or grammatical errors
- [ ] Follows documentation standards

**Testing**:
- [ ] Tested in sufficient repos (per standards)
- [ ] Test results documented
- [ ] Migration tested (if breaking change)

**Process**:
- [ ] CHANGELOG.md updated
- [ ] Proper commit message format
- [ ] PR description complete

---

## Common Patterns

### Adding a New Rule

1. **Identify layer**: Where does this rule belong?
2. **Check for conflicts**: Does it contradict existing rules?
3. **Write rule clearly**: Use examples (✅ GOOD / ❌ BAD)
4. **Add to appropriate file**:
   - Behavioral rule → `core/rules/SYSTEM.md`
   - AI responsibility → `core/rules/AGENT_CONTRACT.md`
   - Infrastructure safety → `iac/conventions/deployment-safety.md`
   - Terraform standard → `terraform/conventions/tofu-standards.md`
5. **Test in 2+ repos**
6. **Update CHANGELOG.md**
7. **Create PR**

---

### Adding a New Routing Pattern

1. **Identify trigger**: What phrase triggers this routing?
2. **Determine tier**: Which tier does it load? (1, 2, or 3)
3. **Add to ROUTING.md**:
   - Add to trigger phrase table
   - Add example to decision tree
4. **Test in 2+ repos**:
   - Use trigger phrase
   - Verify correct context loaded
5. **Update CHANGELOG.md**
6. **Create PR**

---

### Fixing Documentation

1. **Identify issue**: What's wrong? (typo, unclear, incorrect)
2. **Make minimal fix**: Don't refactor unrelated content
3. **Verify accuracy**: Is the fix correct?
4. **Test if content changed**: If examples changed, test them
5. **Create PR** with "docs:" prefix

---

## Communication

### Discussion Channels

- **Issues**: For proposals, questions, bug reports
- **PRs**: For concrete changes with code
- **#infrastructure**: For quick questions (Slack/Discord)

### Getting Help

If you're unsure:
1. Open an issue describing what you want to change
2. Tag maintainers
3. Wait for feedback before implementing

### Proposing Large Changes

For significant changes:
1. Write RFC (Request for Comments) issue
2. Describe:
   - Problem you're solving
   - Proposed solution
   - Alternatives considered
   - Migration plan (if breaking)
3. Get consensus before implementing
4. Create PR with approved RFC

---

## Commit Message Format

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

<body - optional>

<footer - optional>
```

### Types

- `feat`: New feature (minor version bump)
- `fix`: Bug fix (patch version bump)
- `docs`: Documentation only
- `chore`: Maintenance (version bump, etc.)
- `breaking`: Breaking change (major version bump)
- `feat!`: Breaking feature (major version bump)

### Examples

```
feat(core): Add debug workflow routing pattern

Add routing logic for debugging tasks. Triggers when user says
"troubleshoot" or "debug". Loads Tier 2 + troubleshooting.md.

Tested in: tf-msvcs, web-api
```

```
fix(iac): Correct validation script path in deployment-safety.md

The path was listed as ./validate_env.sh but should be
./scripts/validate_env.sh

Fixes: #123
```

```
feat!(core): Rename 00_INDEX to INDEX for simplicity

BREAKING CHANGE: Entrypoint moved from 00_INDEX/ to INDEX/

Migration:
- Update manifest.json entrypoint paths
- Remove "00_" prefix from references

See: MIGRATIONS/v1-to-v2.md for full guide
```

---

## Release Process

### For Maintainers

1. **Merge PRs** for version X.Y.Z
2. **Verify VERSION file** has correct version
3. **Verify CHANGELOG.md** has all changes
4. **Create release tag**:
   ```bash
   git tag -a vX.Y.Z -m "Release vX.Y.Z"
   git push origin vX.Y.Z
   ```
5. **Create GitHub release** with changelog excerpt
6. **Notify users** (if major version)

---

## Questions?

- Open an issue for questions
- Tag maintainers: @maintainer1, @maintainer2
- Ask in #infrastructure channel

---

## License

Internal use within DTLR organization only.
