# Project Configuration Templates

**Stack-aware config templates with strong applicability inference.**

These templates help AI agents suggest relevant configuration files based on detected project types. Each template includes official documentation links, decision guides, and explicit "when NOT to use" rules.

---

## How to Use

### 1. Detect Project Type First

Before suggesting any config, load the inference rule:
```
.governance/ai/core/inference-rules/project-type-detection.md
```

This rule scans for marker files and determines which stacks are present.

### 2. Load Relevant Templates

Based on detected project type(s), load templates from the appropriate directories:

| Detected Marker | Load Templates From |
|-----------------|---------------------|
| `package.json` | `javascript/` |
| `tsconfig.json` | `javascript/` (TypeScript variant) |
| `pyproject.toml`, `requirements.txt` | `python/` |
| `go.mod` | `go/` |
| `Cargo.toml` | `rust/` |
| `*.tf` files | `iac/` |
| `Dockerfile` | `docker/` |
| Any project | `_common/`, `ignore-files/` |

### 3. Apply with Customization

Each template contains `<PLACEHOLDER>` markers. Replace these with project-specific values.

---

## Directory Structure

```
project-configs/
├── README.md                 # This file
├── _common/                  # Stack-agnostic configs
│   ├── editorconfig.template
│   ├── gitignore-patterns.md
│   ├── makefile.template
│   └── scripts-patterns.md
├── javascript/               # JS/TS/Node ecosystem
│   ├── README.md
│   ├── eslint.template
│   ├── prettier.template
│   ├── tsconfig.template
│   ├── turbo.template
│   └── package-scripts.md
├── python/                   # Python ecosystem
│   ├── README.md
│   ├── pyproject.template
│   ├── ruff.template
│   └── requirements-patterns.md
├── go/                       # Go ecosystem
│   ├── README.md
│   ├── gomod.template
│   └── golangci.template
├── iac/                      # Infrastructure-as-Code
│   ├── README.md
│   ├── terraform-provider.template
│   └── tflint.template
├── rust/                     # Rust ecosystem
│   ├── README.md
│   ├── cargo.template
│   └── rustfmt.template
├── docker/                   # Containerization
│   ├── README.md
│   ├── dockerfile-patterns.md
│   └── dockerignore.template
├── caching/                  # Build & dependency caching
│   ├── README.md
│   ├── turbo-cache.md
│   ├── npm-cache.md
│   └── build-cache-patterns.md
└── ignore-files/             # All .ignore file types
    ├── README.md
    ├── gitignore.template
    ├── dockerignore.template
    ├── eslintignore.template
    ├── prettierignore.template
    └── cursorignore.template
```

---

## Template Format

Every template follows this structure:

```markdown
# <Config Name> Template

## Purpose
[1-2 sentence description]

## Official Documentation
- [Primary docs](URL) - Main reference
- [Config reference](URL) - All options

## When to Use
- ✅ [Conditions when this applies]

## When NOT to Use
- ❌ [Explicit exclusions]

## Required Marker Files
- [Files that MUST exist]

## Trade-offs & Alternatives
- [Other tools, when to choose them]

## Integration Notes
- [How this wires with other configs]

## Template
[The actual config with <PLACEHOLDERS>]

## Customization Points
- [What to change and why]
```

---

## Quick Reference: Config by Stack

### JavaScript/TypeScript
| Config | Purpose | Required When |
|--------|---------|---------------|
| `eslint.config.js` | Linting | package.json exists |
| `.prettierrc` | Formatting | package.json exists |
| `tsconfig.json` | TypeScript compilation | .ts files exist |
| `turbo.json` | Monorepo builds | Multiple packages |

### Python
| Config | Purpose | Required When |
|--------|---------|---------------|
| `pyproject.toml` | Project metadata + tools | Python project |
| `ruff.toml` | Linting + formatting | Python project |

### Go
| Config | Purpose | Required When |
|--------|---------|---------------|
| `go.mod` | Module definition | Go project |
| `.golangci.yml` | Linting | Go project |

### IaC/Terraform
| Config | Purpose | Required When |
|--------|---------|---------------|
| `versions.tf` | Provider constraints | .tf files exist |
| `.tflint.hcl` | Linting | .tf files exist |

### Universal (Any Stack)
| Config | Purpose | Required When |
|--------|---------|---------------|
| `.editorconfig` | Editor consistency | Any text files |
| `.gitignore` | Git exclusions | Any git repo |
| `Makefile` | Task automation | Any project |

---

## Negative Inference Quick Reference

| If ONLY These Exist | Skip These Configs |
|---------------------|-------------------|
| `*.sh`, `Makefile` | eslint, prettier, tsconfig, pyproject, turbo |
| `*.tf` | package.json, pyproject, cargo |
| `go.mod` | package.json, pyproject, cargo, turbo |
| `*.py` | tsconfig, cargo, go.mod |
| `Dockerfile` only | All language-specific linting |

---

## Adding New Templates

When adding a new config template:

1. **Create in appropriate stack directory**
2. **Follow the template format** (sections above)
3. **Include official doc links**
4. **Add "When NOT to Use" section** - This is critical
5. **Update this README** - Add to quick reference tables
6. **Update inference rule** if new marker file type

---

## Related Documentation

- Inference Rule: `../../../../../../core/inference-rules/project-type-detection.md`
- Governance Templates: `../governance/`
- Router: `../../router.md`
