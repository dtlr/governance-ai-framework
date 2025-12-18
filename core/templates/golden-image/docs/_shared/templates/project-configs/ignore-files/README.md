# Ignore Files Reference

## Purpose

Comprehensive guide to all ignore file types, their purposes, syntax differences, and when to use each.

## Quick Reference

| File | Tool | Purpose | Syntax |
|------|------|---------|--------|
| `.gitignore` | Git | Exclude files from version control | gitignore |
| `.dockerignore` | Docker | Exclude files from build context | gitignore-like |
| `.eslintignore` | ESLint | Exclude files from JS/TS linting | gitignore |
| `.prettierignore` | Prettier | Exclude files from formatting | gitignore |
| `.cursorignore` | Cursor IDE | Exclude files from AI context | gitignore |
| `.npmignore` | npm | Exclude files from published package | gitignore |

## Syntax Overview

All ignore files use **gitignore-style syntax** with minor variations:

```gitignore
# Comments start with #
file.txt           # Exact file match
*.log              # Glob pattern
dir/               # Directory (trailing slash)
/root-only         # Anchored to root (leading slash)
!important.log     # Negation (include despite earlier exclusion)
**/deep/match      # Match at any depth
```

## Template Files

### Core Templates

| Template | Use When |
|----------|----------|
| `gitignore.template` | Any git repository |
| `dockerignore.template` | Projects with Dockerfile |
| `cursorignore.template` | Teams using Cursor IDE |

### Language-Specific Templates

| Template | Use When |
|----------|----------|
| `eslintignore.template` | JavaScript/TypeScript projects |
| `prettierignore.template` | Projects using Prettier |

## Common Pitfalls

### 1. Pattern Precedence
Later patterns override earlier ones. Order matters:
```gitignore
# This excludes everything then includes .gitkeep
*
!.gitkeep
```

### 2. Negation Only Works for Files
```gitignore
# This WON'T work - can't negate a directory's contents
node_modules/
!node_modules/important-package/  # Ignored!

# Instead, be specific about what to ignore
node_modules/*
!node_modules/important-package/
```

### 3. Trailing Slash Matters
```gitignore
logs    # Matches file OR directory named "logs"
logs/   # Only matches directory named "logs"
```

### 4. Leading Slash Anchors to Root
```gitignore
/dist/   # Only matches <root>/dist/
dist/    # Matches dist/ anywhere in tree
```

## Ignore File Interactions

### What Each File Affects

```
                    ┌─────────────────────────────────────────────────────┐
                    │                   Source Files                       │
                    └─────────────────────────────────────────────────────┘
                                           │
         ┌─────────────────────────────────┼─────────────────────────────────┐
         │                                 │                                 │
         ▼                                 ▼                                 ▼
   ┌───────────┐                    ┌───────────┐                    ┌───────────┐
   │   Git     │                    │  Docker   │                    │  Cursor   │
   │ Repository│                    │   Image   │                    │ AI Context│
   └───────────┘                    └───────────┘                    └───────────┘
         │                                 │                                 │
   .gitignore                       .dockerignore                    .cursorignore
         │                                 │                                 │
         │                                 │                                 │
         ▼                                 ▼                                 ▼
   ┌───────────┐                    ┌───────────┐                    ┌───────────┐
   │ Committed │                    │  Build    │                    │ Visible   │
   │   Files   │                    │  Context  │                    │ to AI     │
   └───────────┘                    └───────────┘                    └───────────┘
```

### Typical Overlap

Most files should be in multiple ignore files:

| Pattern | .gitignore | .dockerignore | .cursorignore |
|---------|:----------:|:-------------:|:-------------:|
| `node_modules/` | ✓ | ✓ | ✓ |
| `.env` | ✓ | ✓ | ✓ |
| `dist/` | ✓ | Optional | ✓ |
| `.git/` | N/A | ✓ | N/A |
| `*.log` | ✓ | ✓ | ✓ |
| `*.md` | ✗ | Optional | ✗ |

## Creating Ignore Files

### Step 1: Start with Universal Patterns

Every project needs these in `.gitignore`:
```gitignore
# OS files
.DS_Store
Thumbs.db

# Editor files
*.swp
*~

# Environment
.env
.env.local
```

### Step 2: Add Stack-Specific Patterns

Use patterns from `_common/gitignore-patterns.md` based on detected project type.

### Step 3: Create Tool-Specific Ignores

If using Docker, ESLint, Prettier, or Cursor, create their respective ignore files.

### Step 4: Verify with Commands

```bash
# Check what git ignores
git check-ignore -v <file>

# List all ignored files
git status --ignored

# Check docker build context
docker build --no-cache . 2>&1 | head -20
```

## Per-Tool Details

### .gitignore
- **Purpose**: Exclude from version control
- **Syntax**: Full gitignore
- **Location**: Repository root (can also be in subdirectories)
- **Documentation**: [git-scm.com/docs/gitignore](https://git-scm.com/docs/gitignore)

### .dockerignore
- **Purpose**: Reduce build context size, exclude secrets
- **Syntax**: gitignore-like (some differences)
- **Location**: Same directory as Dockerfile
- **Documentation**: [docs.docker.com/reference/dockerfile/#dockerignore-file](https://docs.docker.com/reference/dockerfile/#dockerignore-file)
- **Key difference**: `.git/` should be ignored (not needed in container)

### .eslintignore
- **Purpose**: Exclude files from ESLint linting
- **Syntax**: gitignore
- **Location**: Project root
- **Documentation**: [eslint.org/docs/latest/use/configure/ignore](https://eslint.org/docs/latest/use/configure/ignore)
- **Note**: ESLint 9+ uses `ignores` in config file instead

### .prettierignore
- **Purpose**: Exclude files from Prettier formatting
- **Syntax**: gitignore
- **Location**: Project root
- **Documentation**: [prettier.io/docs/en/ignore](https://prettier.io/docs/en/ignore)

### .cursorignore
- **Purpose**: Exclude files from Cursor AI context
- **Syntax**: gitignore
- **Location**: Project root
- **Documentation**: [cursor.com/docs](https://cursor.com/docs)
- **Use case**: Exclude large generated files, vendor code, secrets

### .npmignore
- **Purpose**: Exclude files from npm package publication
- **Syntax**: gitignore
- **Location**: Package root
- **Documentation**: [docs.npmjs.com/cli/configuring-npm/package-json#files](https://docs.npmjs.com/cli/configuring-npm/package-json#files)
- **Note**: If missing, uses `.gitignore` patterns

## Anti-Patterns

❌ **DO NOT:**
- Ignore the ignore files themselves
- Have conflicting patterns between files
- Ignore files without understanding why
- Forget to update ignore files when adding new tooling
- Use ignore files to hide sensitive data already committed (use git filter-branch)

✅ **DO:**
- Keep ignore files organized with section comments
- Use negation sparingly and document why
- Test patterns before committing
- Sync common patterns across ignore files
- Review ignore files during security audits
