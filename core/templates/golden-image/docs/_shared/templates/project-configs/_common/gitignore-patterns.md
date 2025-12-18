# .gitignore Patterns by Stack

## Purpose

Comprehensive .gitignore patterns organized by project type. Copy relevant sections based on detected stacks.

## Official Documentation

- [Git - gitignore](https://git-scm.com/docs/gitignore) - Pattern syntax
- [GitHub gitignore templates](https://github.com/github/gitignore) - Community templates

## When to Use

- ✅ Any git repository
- ✅ Copy patterns for ALL detected stacks (polyglot repos need multiple sections)

## When NOT to Use

- ❌ Non-git version control systems (use their equivalent)

---

## Universal Patterns (Always Include)

```gitignore
# === Universal ===

# OS generated
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Editor/IDE
*.swp
*.swo
*~
.idea/
*.iml
.vscode/settings.json
.vscode/tasks.json
.vscode/launch.json
*.sublime-workspace

# Logs
*.log
logs/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Environment files (secrets)
.env
.env.local
.env.*.local
*.env

# Temporary files
tmp/
temp/
*.tmp
*.temp
```

---

## JavaScript/Node.js

```gitignore
# === JavaScript/Node ===

# Dependencies
node_modules/
.pnp
.pnp.js

# Build outputs
dist/
build/
out/
.next/
.nuxt/
.output/

# Package manager
package-lock.json  # Optional: some teams commit this
yarn.lock          # Optional: some teams commit this
pnpm-lock.yaml     # Optional: some teams commit this
.npm/
.yarn/

# Cache
.cache/
.parcel-cache/
.turbo/
.eslintcache
.prettiercache
*.tsbuildinfo

# Testing
coverage/
.nyc_output/

# Storybook
storybook-static/
```

---

## TypeScript

```gitignore
# === TypeScript ===
# (Add to JavaScript patterns)

# Build info
*.tsbuildinfo

# Declaration files (if generated)
*.d.ts.map
```

---

## Python

```gitignore
# === Python ===

# Byte-compiled
__pycache__/
*.py[cod]
*$py.class

# Virtual environments
.venv/
venv/
ENV/
env/
.python-version

# Distribution/packaging
*.egg
*.egg-info/
dist/
build/
eggs/
.eggs/
sdist/
wheels/
*.whl

# Installer logs
pip-log.txt
pip-delete-this-directory.txt

# Testing
.pytest_cache/
.coverage
htmlcov/
.tox/
.nox/

# Type checkers
.mypy_cache/
.pytype/
.pyre/

# Jupyter
.ipynb_checkpoints/

# pyenv
.python-version
```

---

## Go

```gitignore
# === Go ===

# Binaries
*.exe
*.exe~
*.dll
*.so
*.dylib

# Test binary
*.test

# Output
bin/

# Dependency directories (if not vendoring)
vendor/

# Go workspace
go.work
```

---

## Rust

```gitignore
# === Rust ===

# Build artifacts
target/
**/*.rs.bk

# Cargo
Cargo.lock  # Optional: commit for binaries, ignore for libraries
```

---

## Terraform/IaC

```gitignore
# === Terraform/OpenTofu ===

# Local .terraform directories
**/.terraform/

# .tfstate files
*.tfstate
*.tfstate.*

# Crash log files
crash.log
crash.*.log

# Sensitive variable files
*.tfvars
*.tfvars.json
!example.tfvars

# Override files
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# CLI configuration
.terraformrc
terraform.rc

# Plan files
*.tfplan
tofu.plan
terraform.plan
```

---

## Docker

```gitignore
# === Docker ===

# Docker build context optimization is in .dockerignore
# These are for git:

# Docker Compose override (local dev)
docker-compose.override.yml
docker-compose.local.yml
```

---

## AI Governance

```gitignore
# === AI Governance ===

# Scratch/working files (never commit)
.ai/_scratch/

# Generated outputs (review before commit)
.ai/_out/
```

---

## Combining Patterns

For a polyglot repo (e.g., TypeScript + Python + Terraform):

```gitignore
# === Universal ===
[paste universal section]

# === JavaScript/Node ===
[paste JS section]

# === TypeScript ===
[paste TS section]

# === Python ===
[paste Python section]

# === Terraform ===
[paste Terraform section]

# === AI Governance ===
[paste AI section]
```

---

## Integration Notes

- **Order matters**: More specific patterns should come after general ones
- **Negation**: Use `!` to un-ignore specific files (e.g., `!.env.example`)
- **Check ignores**: `git check-ignore -v <file>` to debug
- **.gitignore vs .dockerignore**: They have similar syntax but different purposes
