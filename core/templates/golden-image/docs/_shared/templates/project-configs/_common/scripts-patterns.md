# Scripts Directory Patterns

## Purpose

Common patterns for organizing and writing shell scripts in any project. Provides consistent naming, safety conventions, and discovery mechanisms.

## Official Documentation

- [Bash Reference Manual](https://www.gnu.org/software/bash/manual/bash.html) - Complete Bash reference
- [ShellCheck](https://www.shellcheck.net/) - Script linting tool
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html) - Style conventions

## When to Use

- ✅ Any project with automation scripts
- ✅ Projects needing portable task runners
- ✅ CI/CD pipelines with custom logic
- ✅ Development workflow automation

## When NOT to Use

- ❌ Complex logic better suited to Python/Node scripts
- ❌ Windows-only environments (use PowerShell)
- ❌ Simple one-liners (put in Makefile instead)

## Directory Structure

```
scripts/
├── README.md           # Script documentation (required)
├── setup.sh            # First-run setup / onboarding
├── dev.sh              # Start development environment
├── build.sh            # Build/compile project
├── test.sh             # Run test suite
├── lint.sh             # Run linters
├── deploy.sh           # Deployment automation
├── clean.sh            # Clean build artifacts
└── lib/                # Shared functions (optional)
    └── common.sh       # Reusable utilities
```

## Script Template

```bash
#!/usr/bin/env bash
#
# <SCRIPT_NAME> - <ONE_LINE_DESCRIPTION>
#
# Usage: ./scripts/<script_name>.sh [options]
#
# Options:
#   -h, --help     Show this help message
#   -v, --verbose  Enable verbose output
#

set -euo pipefail

# === Configuration ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
VERBOSE="${VERBOSE:-false}"

# === Colors (optional) ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# === Functions ===

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

show_help() {
    sed -n '2,/^$/p' "$0" | sed 's/^# \?//'
    exit 0
}

cleanup() {
    # Called on script exit (success or failure)
    # Add cleanup logic here
    :
}

# === Main ===

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    # Set trap for cleanup
    trap cleanup EXIT

    # Main logic here
    log_info "Starting <SCRIPT_NAME>..."

    # <MAIN_LOGIC>

    log_info "Done!"
}

main "$@"
```

## Safety Patterns

### Always Include

```bash
#!/usr/bin/env bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures
```

### Trap for Cleanup

```bash
cleanup() {
    rm -f "$TEMP_FILE" 2>/dev/null || true
}
trap cleanup EXIT
```

### Quote Variables

```bash
# Good
echo "$USER"
for file in "${FILES[@]}"; do

# Bad
echo $USER
for file in ${FILES[@]}; do
```

### Check Dependencies

```bash
check_deps() {
    local deps=("jq" "curl" "git")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            log_error "Missing dependency: $dep"
            exit 1
        fi
    done
}
```

### Idempotency

```bash
# Make scripts safe to run multiple times
mkdir -p "$OUTPUT_DIR"              # Won't fail if exists
rm -f "$TEMP_FILE" 2>/dev/null || true  # Won't fail if missing
```

## Common Patterns by Purpose

### Setup Script

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

main() {
    echo "Setting up project..."

    # Check prerequisites
    command -v <TOOL> &>/dev/null || { echo "Missing: <TOOL>"; exit 1; }

    # Install dependencies
    <INSTALL_COMMAND>

    # Setup environment
    cp -n .env.example .env 2>/dev/null || true

    # Initialize services
    <INIT_COMMANDS>

    echo "Setup complete! Run './scripts/dev.sh' to start."
}

main "$@"
```

### Build Script

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

BUILD_DIR="${PROJECT_ROOT}/dist"
VERSION="${VERSION:-$(git describe --tags --always 2>/dev/null || echo 'dev')}"

main() {
    echo "Building version: $VERSION"

    # Clean previous build
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"

    # Build
    <BUILD_COMMAND>

    echo "Build complete: $BUILD_DIR"
}

main "$@"
```

### Validation Script

```bash
#!/usr/bin/env bash
set -euo pipefail

ERRORS=0

check() {
    local name="$1"
    shift
    if "$@"; then
        echo "✓ $name"
    else
        echo "✗ $name"
        ((ERRORS++))
    fi
}

main() {
    echo "Running validations..."

    check "Lint" <LINT_COMMAND>
    check "Types" <TYPE_CHECK_COMMAND>
    check "Tests" <TEST_COMMAND>

    echo ""
    if [[ $ERRORS -eq 0 ]]; then
        echo "All checks passed!"
    else
        echo "$ERRORS check(s) failed"
        exit 1
    fi
}

main "$@"
```

## Integration with Makefile

Scripts work best alongside a Makefile for discoverability:

```makefile
.PHONY: setup dev build test

setup:
	./scripts/setup.sh

dev:
	./scripts/dev.sh

build:
	./scripts/build.sh

test:
	./scripts/test.sh
```

## README Template

Every `scripts/` directory should have a README:

```markdown
# Scripts

Project automation scripts.

## Available Scripts

| Script | Purpose |
|--------|---------|
| `setup.sh` | First-time project setup |
| `dev.sh` | Start development environment |
| `build.sh` | Build for production |
| `test.sh` | Run test suite |
| `lint.sh` | Run linters |
| `deploy.sh` | Deploy to environment |

## Usage

All scripts should be run from the project root:

```bash
./scripts/setup.sh
./scripts/dev.sh
```

## Adding New Scripts

1. Use the template from `<GOVERNANCE_PATH>/scripts-patterns.md`
2. Include header documentation
3. Add `set -euo pipefail`
4. Update this README
```

## Naming Conventions

| Convention | Example | Use For |
|------------|---------|---------|
| `verb.sh` | `build.sh`, `test.sh` | Action scripts |
| `verb_noun.sh` | `update_deps.sh` | Specific operations |
| `check_*.sh` | `check_env.sh` | Validation scripts |
| `lib/*.sh` | `lib/common.sh` | Shared functions |

## Anti-Patterns

❌ **DO NOT:**
- Use `#!/bin/bash` (use `#!/usr/bin/env bash` for portability)
- Skip `set -euo pipefail`
- Use unquoted variables
- Assume current directory
- Hardcode absolute paths
- Put complex logic in shell (use Python/Node instead)
- Create scripts without documentation

✅ **DO:**
- Use `set -euo pipefail` always
- Quote all variables
- Use `"${BASH_SOURCE[0]}"` for script location
- Add help text to every script
- Make scripts idempotent
- Use functions for organization
- Add README.md to scripts directory

## Global Reusability Assessment

After creating any script, **assess whether it has global applicability**:

### Assessment Questions
1. Could this script be useful in other repositories?
2. Is it generic enough to work across different project types?
3. Does it solve a common problem not specific to this repo?

### If Globally Reusable

1. **Propose for templating** - Add to governance framework
2. **Mark customization points** - Use `<PLACEHOLDER>` for repo-specific values
3. **Add decision sections** - "When to Use" and "When NOT to Use"
4. **File appropriately**:
   - General scripts → `_common/scripts-patterns.md`
   - Stack-specific → `javascript/`, `python/`, etc.

### Examples

**Globally Reusable:**
- Environment validation scripts
- Development server starters
- Test/lint/format runners
- Dependency update scripts
- Setup/onboarding scripts

**Repo-Specific (don't template):**
- Scripts with hardcoded project paths
- Business logic specific to one project
- One-off data migrations
- Proprietary system integrations

### Template Extraction Workflow

```bash
# 1. Identify customization points
grep -n "hardcoded-value" script.sh

# 2. Replace with placeholders
sed -i 's/hardcoded-value/<PROJECT_NAME>/g' script.sh

# 3. Add header documentation
# Purpose, When to Use, When NOT to Use

# 4. Add to governance framework templates
# core/templates/golden-image/docs/_shared/templates/project-configs/_common/
```
