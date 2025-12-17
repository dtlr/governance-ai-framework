# DTLR Git Workflow Standards

## Commit Message Format

All commits follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `chore`: Maintenance (dependencies, configs)
- `refactor`: Code restructuring (no behavior change)
- `test`: Adding or updating tests
- `perf`: Performance improvement
- `ci`: CI/CD changes

### Examples
```
feat(auth): Add OAuth2 integration with Azure AD

Implements OAuth2 authorization code flow for Azure AD authentication.
Includes token refresh logic and session management.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

```
fix(api): Prevent null pointer exception in user lookup

Added null check before accessing user.profile to prevent crashes
when profile hasn't been created yet.

Fixes #123
```

## Branch Strategy

### Main Branches
- `main` - Production-ready code
- `develop` - Integration branch (if using GitFlow)

### Feature Branches
- `feature/<description>` - New features
- `fix/<description>` - Bug fixes
- `chore/<description>` - Maintenance work

### Examples
```bash
git checkout -b feature/add-oauth-integration
git checkout -b fix/user-profile-null-check
git checkout -b chore/update-dependencies
```

## Pull Request Guidelines

### Title Format
Use same format as commit messages:
```
feat(auth): Add OAuth2 integration
fix(api): Prevent null pointer in user lookup
```

### PR Description Template
```markdown
## Summary
Brief description of changes

## Changes
- Bullet list of specific changes
- What was added/modified/removed

## Testing
How to test these changes

## Related Issues
Fixes #123
Part of #456
```

## AI Co-Authorship

All AI-assisted commits MUST include footer:

```
🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

Or for other AI tools:
```
Co-Authored-By: GitHub Copilot <noreply@github.com>
Co-Authored-By: Cursor AI <noreply@cursor.sh>
```

## Governance Submodule Changes

When making changes to governance submodules:

### 1. Make Changes in Submodule
```bash
cd .governance/core
git checkout -b feature/new-inference-rule
# Make changes...
git commit -m "feat: Add inference rule for API errors"
git push origin feature/new-inference-rule
```

### 2. Create PR in Governance Repo
- Open PR in dtlr/governance-core
- Get approval from governance maintainers
- Merge to main

### 3. Update Parent Repo
```bash
cd .governance/core
git pull origin main
cd ../..
git add .governance/core
git commit -m "chore: Update governance-core to latest

Includes new inference rule for API error handling."
git push
```

### 4. Notify Other Repos
- Post in #engineering channel
- List breaking changes (if any)
- Provide migration guide

## Protected Branches

### main branch
- Requires PR review
- Requires passing CI
- No direct pushes
- Auto-merge dependabot (minor/patch only)

## Workflow Summary

```
1. Create feature branch from main
2. Make changes + commit (with AI co-author if applicable)
3. Push branch
4. Create PR
5. Get review + approval
6. CI passes
7. Merge to main
8. Delete feature branch
```
