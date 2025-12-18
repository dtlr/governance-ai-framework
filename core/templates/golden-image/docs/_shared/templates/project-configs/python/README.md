# Python Configuration Templates

## Overview

Configuration templates for Python projects, covering project metadata, dependency management, linting, and formatting.

## Detection

**Marker Files:**
- `pyproject.toml` → Modern Python project
- `requirements.txt` → Legacy/simple Python project
- `setup.py` → Legacy Python package

**Load When:** Any of these markers exist

## Template Hierarchy

```
python/
├── README.md              # This file
├── pyproject.template     # Project metadata and tool config
├── ruff.template          # Linting and formatting (Ruff)
└── requirements-patterns.md  # Requirements file patterns
```

## Quick Reference

| Config | Purpose | Required When |
|--------|---------|---------------|
| `pyproject.toml` | Project metadata, dependencies, tool config | Any Python project |
| `ruff.toml` / `[tool.ruff]` | Linting + formatting | Any Python project |

## Modern Python Stack

The recommended modern Python toolchain:

| Tool | Purpose | Replaces |
|------|---------|----------|
| [uv](https://github.com/astral-sh/uv) | Package/env manager | pip, venv, poetry |
| [Ruff](https://docs.astral.sh/ruff/) | Linting + formatting | flake8, black, isort |
| [pyright](https://microsoft.github.io/pyright/) | Type checking | mypy (optional) |
| [pytest](https://docs.pytest.org/) | Testing | unittest |

## Project Structure

### Application
```
project/
├── pyproject.toml     # Project metadata + tool config
├── src/
│   └── myapp/
│       ├── __init__.py
│       └── main.py
├── tests/
│   ├── __init__.py
│   └── test_main.py
├── .python-version    # Python version (pyenv/uv)
└── .venv/             # Virtual environment (gitignored)
```

### Library (pip-installable)
```
library/
├── pyproject.toml     # Package metadata + build config
├── src/
│   └── mylibrary/
│       ├── __init__.py
│       ├── core.py
│       └── py.typed   # PEP 561 marker
├── tests/
├── README.md
└── LICENSE
```

## Package Managers

| Manager | Use Case | Lock File |
|---------|----------|-----------|
| [uv](https://github.com/astral-sh/uv) | Modern, fast, recommended | `uv.lock` |
| [pip](https://pip.pypa.io/) | Standard, simple | `requirements.txt` |
| [Poetry](https://python-poetry.org/) | All-in-one (legacy choice) | `poetry.lock` |
| [PDM](https://pdm-project.org/) | PEP 582 compliance | `pdm.lock` |

## Config Loading Order

For new Python projects:

1. **Always create:** `pyproject.toml`
2. **Configure Ruff:** Either in `pyproject.toml` or separate `ruff.toml`
3. **Optional:** `requirements.txt` for simple pip workflows

## Integration Points

### pyproject.toml + Ruff

Ruff can be configured inline:

```toml
# pyproject.toml
[tool.ruff]
line-length = 88
target-version = "py311"

[tool.ruff.lint]
select = ["E", "F", "I", "UP"]
```

Or in a separate file:

```toml
# ruff.toml
line-length = 88
target-version = "py311"

[lint]
select = ["E", "F", "I", "UP"]
```

### pytest Configuration

```toml
# pyproject.toml
[tool.pytest.ini_options]
testpaths = ["tests"]
pythonpath = ["src"]
addopts = "-v --tb=short"
```

### Type Checking (pyright)

```toml
# pyproject.toml
[tool.pyright]
pythonVersion = "3.11"
typeCheckingMode = "basic"
```

## When NOT to Use These Templates

| Scenario | Skip These |
|----------|------------|
| JavaScript project | All Python configs |
| Shell scripts only | All Python configs |
| Data science notebooks only | Consider lighter setup |
| Jupyter-only workflow | Use `ipykernel` + minimal pyproject |

## Common Patterns

### Virtual Environment

```bash
# Using uv (recommended)
uv venv
source .venv/bin/activate

# Using venv
python -m venv .venv
source .venv/bin/activate
```

### Development Install

```bash
# Using uv
uv pip install -e ".[dev]"

# Using pip
pip install -e ".[dev]"
```

### Running Tools

```bash
# Linting
ruff check .
ruff check . --fix

# Formatting
ruff format .

# Testing
pytest

# Type checking
pyright
```

## Version Notes

- **Python 3.11+**: Recommended minimum
- **pyproject.toml**: Now standard (PEP 517/518/621)
- **setup.py**: Legacy, avoid in new projects
- **requirements.txt**: Still useful for pinning, but not project metadata
