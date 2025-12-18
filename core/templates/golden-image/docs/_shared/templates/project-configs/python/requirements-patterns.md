# Requirements File Patterns

## Purpose

Patterns for requirements.txt and related dependency files. While pyproject.toml is preferred for modern projects, requirements files remain useful for pinning, Docker builds, and simple scripts.

## Official Documentation

- [pip Requirements Files](https://pip.pypa.io/en/stable/reference/requirements-file-format/) - Full format spec
- [pip Constraints](https://pip.pypa.io/en/stable/user_guide/#constraints-files) - Constraint files

## When to Use

- ✅ Pinned production dependencies (from `pip freeze`)
- ✅ Docker builds needing reproducible installs
- ✅ Legacy projects not using pyproject.toml
- ✅ CI/CD caching based on lockfile hash

## When NOT to Use

- ❌ Primary dependency management (use pyproject.toml)
- ❌ Development dependencies (use `[project.optional-dependencies]`)
- ❌ As source of truth for versions

## File Naming Conventions

| File | Purpose |
|------|---------|
| `requirements.txt` | Production/main dependencies |
| `requirements-dev.txt` | Development dependencies |
| `requirements-test.txt` | Test dependencies only |
| `constraints.txt` | Version constraints (not install) |

## Basic Format

```txt
# requirements.txt
# Comment lines start with #

# Exact version (most reproducible)
requests==2.31.0

# Minimum version
requests>=2.31.0

# Version range
requests>=2.31.0,<3.0.0

# Compatible release (same as >=2.31.0,<2.32.0 per SemVer)
requests~=2.31.0

# Any version (avoid in production)
requests

# From URL
git+https://github.com/user/repo.git@v1.0.0#egg=package

# Local package
-e ./path/to/package
```

## Template: Generated Lockfile

```txt
# requirements.txt
# Generated from pyproject.toml - DO NOT EDIT MANUALLY
# Regenerate with: pip-compile pyproject.toml -o requirements.txt
#
# Last updated: <DATE>

certifi==2024.2.2
charset-normalizer==3.3.2
idna==3.6
requests==2.31.0
urllib3==2.2.1
```

## Template: Hand-Maintained

```txt
# requirements.txt
# Core dependencies

# HTTP client
requests>=2.31.0,<3.0.0

# Data processing
pandas>=2.0.0,<3.0.0
numpy>=1.24.0,<2.0.0

# Include other requirements files
-r requirements-base.txt
```

## Template: Development

```txt
# requirements-dev.txt
# Development dependencies
# Install with: pip install -r requirements-dev.txt

# Include production deps
-r requirements.txt

# Testing
pytest>=8.0.0
pytest-cov>=4.0.0

# Linting/Formatting
ruff>=0.5.0

# Type checking
pyright>=1.1.0
```

## Template: Docker Optimized

```txt
# requirements.txt (for Docker)
# Pinned versions for reproducible builds

# DO NOT use >= ranges in Docker builds
# Always pin exact versions

requests==2.31.0
pydantic==2.6.0
fastapi==0.109.0
uvicorn[standard]==0.27.0
```

## Using Constraints

Constraints separate version pinning from installation:

```txt
# constraints.txt
requests==2.31.0
urllib3==2.2.1
```

```bash
# Apply constraints during install
pip install -c constraints.txt -r requirements.txt
```

## Using pip-tools

Best practice: Generate lockfile from pyproject.toml.

```bash
# Install pip-tools
pip install pip-tools

# Compile requirements from pyproject.toml
pip-compile pyproject.toml -o requirements.txt

# Compile with dev deps
pip-compile pyproject.toml --extra dev -o requirements-dev.txt

# Sync environment to requirements
pip-sync requirements.txt

# Upgrade all packages
pip-compile --upgrade pyproject.toml -o requirements.txt
```

## Patterns by Use Case

### Docker Build

```dockerfile
# Dockerfile
FROM python:3.11-slim

WORKDIR /app

# Copy requirements first for layer caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Then copy application
COPY . .
```

### CI/CD Caching

```yaml
# GitHub Actions
- uses: actions/cache@v4
  with:
    path: ~/.cache/pip
    key: ${{ runner.os }}-pip-${{ hashFiles('requirements*.txt') }}
```

### Multiple Environments

```
requirements/
├── base.txt           # Shared dependencies
├── production.txt     # Production only
├── development.txt    # Dev tools
└── test.txt          # Test dependencies
```

```txt
# requirements/production.txt
-r base.txt
gunicorn==21.2.0
```

```txt
# requirements/development.txt
-r base.txt
-r test.txt
ruff>=0.5.0
```

## Migration to pyproject.toml

If moving from requirements.txt to pyproject.toml:

```bash
# 1. Read current deps
cat requirements.txt

# 2. Add to pyproject.toml [project.dependencies]

# 3. Use pip-tools to maintain lock
pip-compile pyproject.toml -o requirements.txt

# 4. Keep requirements.txt for Docker/CI caching
```

## Anti-Patterns

❌ **Avoid:**
```txt
# No version pin (unpredictable)
requests

# Too loose (major version changes)
requests>=1.0.0

# Editing generated lockfile
# These should be regenerated, not hand-edited
```

✅ **Prefer:**
```txt
# Explicit versions for production
requests==2.31.0

# Ranges for flexibility (in pyproject.toml, not requirements.txt)
requests>=2.31.0,<3.0.0

# Regenerate, don't edit
# pip-compile --upgrade pyproject.toml
```

## Validation

```bash
# Check for outdated packages
pip list --outdated

# Verify requirements install cleanly
pip install --dry-run -r requirements.txt

# Check for security vulnerabilities
pip-audit -r requirements.txt
```
