# Inference: Project Type Detection

## Intent

Detect project types from marker files and guide AI agents on which configuration files are relevant, preventing irrelevant suggestions (e.g., eslint for bash-only projects).

**Load When:** Creating config files, suggesting tooling, setting up projects, reviewing configurations.

---

## Marker File Detection

| Marker File(s) | Project Type | Relevant Configs |
|----------------|--------------|------------------|
| `package.json` | JavaScript/Node | eslint, prettier, tsconfig, turbo, npm scripts |
| `tsconfig.json` | TypeScript | TypeScript-specific eslint, tsconfig |
| `pyproject.toml`, `requirements.txt`, `setup.py` | Python | pyproject, ruff, mypy |
| `go.mod` | Go | golangci-lint, go.mod patterns |
| `Cargo.toml` | Rust | cargo, clippy, rustfmt |
| `*.tf`, `terragrunt.hcl` | Terraform/IaC | tflint, provider configs, backend patterns |
| `Dockerfile` | Docker | .dockerignore, hadolint |
| `turbo.json` | Monorepo | turbo config, workspace patterns |
| `Makefile` only (no others) | Make/Shell | editorconfig only |

---

## Decision Rules

### Rule 1: Scan Before Suggesting

Before suggesting ANY config file:

1. **Identify marker files** in repo root and common locations
2. **Map to project type(s)** using the table above
3. **Only suggest configs** for detected types
4. **State skipped configs** and why they're irrelevant

### Rule 2: Polyglot/Monorepo Detection

If multiple marker types exist:
- Treat as **polyglot** or **monorepo**
- Suggest configs for **ALL** detected types
- Note **integration points** between stacks (e.g., Python + TypeScript in same repo)

### Rule 3: Negative Inference (When NOT Relevant)

| If Repo Contains ONLY | These Configs are IRRELEVANT |
|----------------------|------------------------------|
| `*.sh`, `Makefile` | eslint, prettier, tsconfig, pyproject, turbo, cargo |
| `*.tf` files | package.json, pyproject, cargo, go.mod |
| `go.mod` | package.json, pyproject, cargo, turbo |
| `*.py` files | tsconfig, cargo, go.mod, turbo |
| `Cargo.toml` | package.json, pyproject, go.mod |
| `Dockerfile` only | All language-specific linting/formatting |

### Rule 4: Universal Configs (Always Relevant)

These configs are **stack-agnostic** and apply to any project:

| Config | When Relevant |
|--------|---------------|
| `.editorconfig` | Any project with text files |
| `.gitignore` | Any git repository |
| `.cursorignore` | Any repo using Cursor IDE |
| `Makefile` | Any project (optional task runner) |

### Rule 5: Applicability Check

Before creating/suggesting a config, verify:

1. ✅ Does a marker file for this stack exist?
2. ✅ Is this config type already present? (don't duplicate)
3. ✅ Would this config serve any files in the repo?
4. ✅ Has the user indicated this stack is relevant?

---

## Detection Decision Tree

```
Config Question / Setup Request
    │
    ├─ Scan repo root for marker files
    │
    ├─ package.json exists?
    │   ├─ YES → JavaScript stack detected
    │   │   ├─ tsconfig.json exists? → TypeScript variant
    │   │   ├─ turbo.json exists? → Monorepo variant
    │   │   └─ Relevant: eslint, prettier, tsconfig, turbo, package-scripts
    │   └─ NO → Continue scanning
    │
    ├─ pyproject.toml OR requirements.txt OR setup.py?
    │   ├─ YES → Python stack detected
    │   │   └─ Relevant: pyproject, ruff, mypy, requirements patterns
    │   └─ NO → Continue scanning
    │
    ├─ go.mod exists?
    │   ├─ YES → Go stack detected
    │   │   └─ Relevant: golangci-lint, go.mod patterns
    │   └─ NO → Continue scanning
    │
    ├─ *.tf files exist?
    │   ├─ YES → IaC/Terraform stack detected
    │   │   └─ Relevant: tflint, provider configs, backend patterns
    │   └─ NO → Continue scanning
    │
    ├─ Cargo.toml exists?
    │   ├─ YES → Rust stack detected
    │   │   └─ Relevant: cargo, clippy, rustfmt
    │   └─ NO → Continue scanning
    │
    ├─ Dockerfile exists?
    │   ├─ YES → Add Docker to detected stacks
    │   │   └─ Relevant: .dockerignore, dockerfile patterns
    │   └─ NO → Skip Docker configs
    │
    ├─ Multiple markers found?
    │   └─ YES → Polyglot/monorepo mode
    │       └─ Load ALL relevant stack templates
    │
    └─ Only Makefile / shell scripts?
        └─ Minimal tooling mode
            ├─ Relevant: editorconfig, gitignore
            └─ SKIP: All language-specific linting/formatting
```

---

## Output Contract

When suggesting configs, ALWAYS state:

```markdown
## Detected Project Type(s)
- [List detected stacks with marker files found]

## Relevant Configs
- [List configs that apply to detected stacks]

## Skipped Configs (Not Relevant)
- [List configs that DON'T apply and why]
  - Example: "eslint - No JavaScript files detected"
  - Example: "pyproject.toml - No Python marker files found"
```

---

## Integration with Config Templates

Config templates are located at:
```
.governance/ai/core/templates/golden-image/docs/_shared/templates/project-configs/
├── _common/          # Stack-agnostic (always load)
├── javascript/       # Load if package.json detected
├── python/           # Load if pyproject.toml/requirements.txt detected
├── go/               # Load if go.mod detected
├── iac/              # Load if *.tf files detected
├── rust/             # Load if Cargo.toml detected
├── docker/           # Load if Dockerfile detected
├── caching/          # Load for build optimization questions
└── ignore-files/     # Load for ignore file questions
```

Each template includes:
- **When to Use** - Specific conditions
- **When NOT to Use** - Explicit exclusions
- **Official Docs** - Links to references
- **Trade-offs** - Alternatives and considerations

---

## Anti-Patterns

❌ **DO NOT:**
- Suggest eslint/prettier for Terraform-only repos
- Add tsconfig to Python projects
- Create pyproject.toml for shell script collections
- Assume all repos need all configs
- Skip the detection scan
- Suggest configs without stating relevance

✅ **DO:**
- Scan for marker files first
- State which stacks were detected
- Explain why configs are/aren't relevant
- Handle polyglot repos correctly
- Suggest universal configs (editorconfig, gitignore) when appropriate

---

## Examples

### Example 1: Terraform Repository

**Detected:** `*.tf` files, `Makefile`

```
Detected Project Type(s):
- Terraform/IaC (main.tf, variables.tf found)
- Make/Shell (Makefile found)

Relevant Configs:
- .editorconfig (universal)
- .gitignore (universal + terraform patterns)
- tflint (Terraform linting)
- terraform provider constraints

Skipped Configs (Not Relevant):
- eslint - No JavaScript files
- prettier - No JavaScript files
- pyproject.toml - No Python files
- tsconfig.json - No TypeScript files
- turbo.json - Not a JS monorepo
```

### Example 2: TypeScript Monorepo

**Detected:** `package.json`, `tsconfig.json`, `turbo.json`

```
Detected Project Type(s):
- JavaScript/Node (package.json found)
- TypeScript (tsconfig.json found)
- Monorepo (turbo.json found)

Relevant Configs:
- .editorconfig (universal)
- .gitignore (universal + node patterns)
- eslint.config.js (JS/TS linting)
- prettier.config.js (formatting)
- tsconfig.json (TypeScript)
- turbo.json (monorepo build)

Skipped Configs (Not Relevant):
- pyproject.toml - No Python files
- go.mod - No Go files
- Cargo.toml - No Rust files
```

### Example 3: Pure Shell Scripts

**Detected:** `*.sh` files, `Makefile` only

```
Detected Project Type(s):
- Shell/Make (only shell scripts and Makefile found)

Relevant Configs:
- .editorconfig (universal - set shell file patterns)
- .gitignore (universal)

Skipped Configs (Not Relevant):
- eslint - No JavaScript files
- prettier - No JavaScript files
- pyproject.toml - No Python files
- tsconfig.json - No TypeScript files
- All language-specific tooling - Shell scripts use shellcheck if needed
```

---

## Related Documentation

- `lazy-loading.md` - Context tier loading
- `three-tier-system.md` - Progressive disclosure
- `directory-contract.md` - File classification
- Config templates: `core/templates/golden-image/docs/_shared/templates/project-configs/`
