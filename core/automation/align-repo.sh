#!/usr/bin/env bash
set -euo pipefail

# align-repo.sh - Portable repo alignment script
#
# DEFAULT: Always dry-run first and generate documentation
# Then user chooses: accept | defer | destroy
#
# Usage:
#   /path/to/align-repo.sh                    # Dry-run + docs (default)
#   /path/to/align-repo.sh --apply            # Execute after review
#   /path/to/align-repo.sh --defer            # Create GitHub backlog issue
#   /path/to/align-repo.sh --destroy          # Clean up generated files

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# Defaults - DRY_RUN IS TRUE BY DEFAULT
DRY_RUN=true
APPLY=false
DEFER=false
DESTROY=false
INTERACTIVE=true
SKIP_UPDATE=false
TARGET_DIR=""
SESSION_ID=$(date +%Y%m%d-%H%M%S)
START_TIME=$(date +%s)
PLAN_FILE=""

# Track what would be done
declare -a PLAN_ACTIONS=()
declare -a PLAN_FILES_CREATED=()
declare -a PLAN_FILES_REPLACED=()
declare -a PLAN_CONTRIBUTIONS=()

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

${BOLD}Portable repo alignment - always dry-run first.${NC}

${CYAN}Workflow:${NC}
    1. Run without flags → generates ALIGNMENT_PLAN.md
    2. Review the plan
    3. Choose: --apply | --defer | --destroy

${CYAN}Options:${NC}
    --target <dir>      Align a specific directory (default: current dir)
    --apply             Execute the plan (after review)
    --defer             Create GitHub issue for later
    --destroy           Clean up all generated files
    --force             Skip dry-run (dangerous)
    --non-interactive   Don't prompt for contributions
    --skip-update       Don't update submodule version
    -h, --help          Show this help

${CYAN}Examples:${NC}
    # Step 1: Generate plan (default)
    align-repo.sh
    
    # Step 2a: Accept and execute
    align-repo.sh --apply
    
    # Step 2b: Defer to backlog
    align-repo.sh --defer
    
    # Step 2c: Discard everything
    align-repo.sh --destroy
EOF
    exit 0
}

log() {
    local level="$1"; shift
    case "$level" in
        INFO)   echo -e "${BLUE}ℹ${NC} $*" ;;
        OK)     echo -e "${GREEN}✓${NC} $*" ;;
        WARN)   echo -e "${YELLOW}⚠${NC} $*" ;;
        ERROR)  echo -e "${RED}✗${NC} $*" ;;
        STEP)   echo -e "${MAGENTA}→${NC} $*" ;;
        DIFF)   echo -e "${CYAN}≠${NC} $*" ;;
        PLAN)   echo -e "${CYAN}📋${NC} $*" ;;
        DRY)    echo -e "${YELLOW}[DRY-RUN]${NC} $*" ;;
    esac
}

plan_action() {
    local action="$1"
    PLAN_ACTIONS+=("$action")
    [[ "$DRY_RUN" == true ]] && log DRY "$action"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --target) TARGET_DIR="$2"; shift 2 ;;
        --apply) APPLY=true; DRY_RUN=false; shift ;;
        --defer) DEFER=true; shift ;;
        --destroy) DESTROY=true; shift ;;
        --force) DRY_RUN=false; shift ;;
        --non-interactive) INTERACTIVE=false; shift ;;
        --skip-update) SKIP_UPDATE=true; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

# Determine target repository
if [[ -n "$TARGET_DIR" ]]; then
    cd "$TARGET_DIR"
fi
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$REPO_ROOT"

PLAN_FILE="$REPO_ROOT/.ai/_scratch/ALIGNMENT_PLAN-$SESSION_ID.md"
PLAN_DIR="$REPO_ROOT/.ai/_scratch/alignment-$SESSION_ID"

# ═══════════════════════════════════════════════════════════════════════════════
# DESTROY MODE - Clean up generated files
# ═══════════════════════════════════════════════════════════════════════════════
if [[ "$DESTROY" == true ]]; then
    echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                    DESTROY MODE                              ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Find and remove alignment artifacts
    found=0
    for f in "$REPO_ROOT/.ai/_scratch/ALIGNMENT_PLAN"*.md; do
        [[ -f "$f" ]] && { echo "  Removing: $f"; rm -f "$f"; ((++found)); }
    done
    for d in "$REPO_ROOT/.ai/_scratch/alignment-"*/; do
        [[ -d "$d" ]] && { echo "  Removing: $d"; rm -rf "$d"; ((++found)); }
    done
    
    if [[ $found -eq 0 ]]; then
        echo -e "${YELLOW}No alignment artifacts found to clean up.${NC}"
    else
        echo ""
        echo -e "${GREEN}✓ Cleaned up $found artifact(s)${NC}"
    fi
    exit 0
fi

# ═══════════════════════════════════════════════════════════════════════════════
# DEFER MODE - Create GitHub issue
# ═══════════════════════════════════════════════════════════════════════════════
if [[ "$DEFER" == true ]]; then
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║                    DEFER TO BACKLOG                          ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Find the most recent plan
    latest_plan=$(ls -t "$REPO_ROOT/.ai/_scratch/ALIGNMENT_PLAN"*.md 2>/dev/null | head -1)
    
    if [[ -z "$latest_plan" ]]; then
        log ERROR "No alignment plan found. Run without flags first to generate one."
        exit 1
    fi
    
    REPO_NAME=$(basename "$REPO_ROOT")
    
    ISSUE_BODY="## Repository Alignment Deferred

**Repository**: \`$REPO_NAME\`
**Session**: \`$SESSION_ID\`
**Generated**: $(date -Iseconds)

### Alignment Plan
\`\`\`
$(cat "$latest_plan")
\`\`\`

### Context
This alignment was reviewed but deferred for later execution.

Run \`align-repo.sh --apply\` to execute.
"
    
    if command -v gh &> /dev/null; then
        issue_url=$(gh issue create \
            --title "🔧 Deferred: Repository Alignment for $REPO_NAME" \
            --body "$ISSUE_BODY" \
            --label "ai-deferred,infrastructure,backlog" 2>/dev/null || echo "")
        
        if [[ -n "$issue_url" ]]; then
            echo -e "${GREEN}✓ GitHub Issue Created: $issue_url${NC}"
            echo "$issue_url" > "$REPO_ROOT/.ai/_scratch/DEFERRED_ISSUE.txt"
        else
            log WARN "gh CLI failed. Saving locally..."
            echo "$ISSUE_BODY" > "$REPO_ROOT/.ai/_scratch/DEFERRED_ALIGNMENT.md"
            echo -e "${YELLOW}Saved: .ai/_scratch/DEFERRED_ALIGNMENT.md${NC}"
        fi
    else
        log WARN "gh CLI not found. Saving locally..."
        echo "$ISSUE_BODY" > "$REPO_ROOT/.ai/_scratch/DEFERRED_ALIGNMENT.md"
        echo -e "${YELLOW}Saved: .ai/_scratch/DEFERRED_ALIGNMENT.md${NC}"
    fi
    
    exit 0
fi

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN: DRY-RUN (default) or APPLY
# ═══════════════════════════════════════════════════════════════════════════════

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
if [[ "$DRY_RUN" == true ]]; then
echo -e "${BLUE}║        ALIGNMENT ANALYSIS (Dry-Run)                          ║${NC}"
else
echo -e "${GREEN}║        EXECUTING ALIGNMENT                                   ║${NC}"
fi
echo -e "${BLUE}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BLUE}║  Target: ${REPO_ROOT}${NC}"
echo -e "${BLUE}║  Session: ${SESSION_ID}${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Setup directories
mkdir -p "$REPO_ROOT/.ai/_scratch" "$REPO_ROOT/.ai/ledger"

# ─── Find governance submodule ────────────────────────────────────────────────
GOVERNANCE_ROOT=""
GOLDEN_IMAGE=""

# Check common locations
for path in ".governance/ai" "governance/ai" ".governance" "node_modules/@dtlr/governance/ai"; do
    if [[ -d "$REPO_ROOT/$path/core/templates/golden-image" ]]; then
        GOVERNANCE_ROOT="$REPO_ROOT/$path"
        GOLDEN_IMAGE="$GOVERNANCE_ROOT/core/templates/golden-image"
        break
    fi
done

# Fallback to script's location
if [[ -z "$GOVERNANCE_ROOT" ]]; then
    potential="$SCRIPT_DIR/../.."
    if [[ -d "$potential/core/templates/golden-image" ]]; then
        GOVERNANCE_ROOT="$potential"
        GOLDEN_IMAGE="$GOVERNANCE_ROOT/core/templates/golden-image"
    fi
fi

if [[ -z "$GOLDEN_IMAGE" ]]; then
    log ERROR "Cannot find golden-image template"
    log INFO "Expected at: <governance>/core/templates/golden-image"
    exit 1
fi

log OK "Found golden-image: $GOLDEN_IMAGE"

# ─── Helper functions ─────────────────────────────────────────────────────────

check_file_needed() {
    local golden_file="$1"
    local relative_path="${golden_file#$GOLDEN_IMAGE/}"
    local local_file="$REPO_ROOT/$relative_path"
    
    if [[ ! -f "$local_file" ]]; then
        echo "CREATE"
    elif ! diff -q "$local_file" "$golden_file" &>/dev/null; then
        echo "REPLACE"
    else
        echo "OK"
    fi
}

show_diff() {
    local local_file="$1"
    local golden_file="$2"
    
    echo ""
    echo -e "${CYAN}═══ DIFF: $(basename "$local_file") ═══${NC}"
    diff -u "$local_file" "$golden_file" 2>/dev/null | head -40 || true
    echo ""
}

# ─── Discover tooling ─────────────────────────────────────────────────────────

discover_tooling() {
    local tools_file="$REPO_ROOT/.ai/TOOLING.md"
    local tools_found=()
    
    log STEP "Discovering repository tooling..."
    
    # Check for various tools
    [[ -f "$REPO_ROOT/.editorconfig" ]] && tools_found+=("EditorConfig|.editorconfig|https://editorconfig.org/")
    [[ -f "$REPO_ROOT/.envrc" ]] && tools_found+=("direnv|.envrc|https://direnv.net/")
    [[ -f "$REPO_ROOT/.tool-versions" ]] && tools_found+=("asdf|.tool-versions|https://asdf-vm.com/")
    
    # Terraform/OpenTofu
    if find "$REPO_ROOT" -maxdepth 3 -name "*.tf" -type f 2>/dev/null | head -1 | grep -q .; then
        tools_found+=("OpenTofu/Terraform|*.tf|https://opentofu.org/docs/")
    fi
    
    # Helm
    if find "$REPO_ROOT" -maxdepth 4 -name "Chart.yaml" -type f 2>/dev/null | head -1 | grep -q .; then
        tools_found+=("Helm|Chart.yaml|https://helm.sh/docs/")
    fi
    
    # Kustomize
    if find "$REPO_ROOT" -maxdepth 4 -name "kustomization.yaml" -type f 2>/dev/null | head -1 | grep -q .; then
        tools_found+=("Kustomize|kustomization.yaml|https://kustomize.io/")
    fi
    
    # GitHub Actions
    [[ -d "$REPO_ROOT/.github/workflows" ]] && tools_found+=("GitHub Actions|.github/workflows/|https://docs.github.com/en/actions")
    
    # Make
    [[ -f "$REPO_ROOT/Makefile" ]] && tools_found+=("Make|Makefile|https://www.gnu.org/software/make/manual/")
    
    # Claude Code
    [[ -f "$REPO_ROOT/CLAUDE.md" ]] && tools_found+=("Claude Code|CLAUDE.md|https://docs.anthropic.com/")
    
    # VSCode
    [[ -d "$REPO_ROOT/.vscode" ]] && tools_found+=("VSCode|.vscode/|https://code.visualstudio.com/docs")
    
    # Ansible
    if find "$REPO_ROOT" -maxdepth 3 -name "ansible.cfg" -o -name "playbook*.yml" 2>/dev/null | head -1 | grep -q .; then
        tools_found+=("Ansible|ansible.cfg|https://docs.ansible.com/")
    fi
    
    # Biome
    [[ -f "$REPO_ROOT/biome.json" ]] && tools_found+=("Biome|biome.json|https://biomejs.dev/")
    
    # Node.js
    [[ -f "$REPO_ROOT/package.json" ]] && tools_found+=("Node.js|package.json|https://nodejs.org/docs/")
    
    # Python
    [[ -f "$REPO_ROOT/pyproject.toml" ]] && tools_found+=("Python/Poetry|pyproject.toml|https://python-poetry.org/docs/")
    [[ -f "$REPO_ROOT/requirements.txt" ]] && tools_found+=("Python/pip|requirements.txt|https://pip.pypa.io/")
    
    # Go
    [[ -f "$REPO_ROOT/go.mod" ]] && tools_found+=("Go|go.mod|https://go.dev/doc/")
    
    # Rust
    [[ -f "$REPO_ROOT/Cargo.toml" ]] && tools_found+=("Rust|Cargo.toml|https://doc.rust-lang.org/cargo/")
    
    if [[ ${#tools_found[@]} -gt 0 ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            plan_action "Would create TOOLING.md with ${#tools_found[@]} detected tools"
            PLAN_FILES_CREATED+=(".ai/TOOLING.md")
        else
            cat > "$tools_file" << HEADER
# Repository Tooling

Auto-discovered tools and their documentation.
Generated: $(date -Iseconds)

| Tool | Config | Documentation |
|------|--------|---------------|
HEADER
            for tool in "${tools_found[@]}"; do
                IFS='|' read -r name config docs <<< "$tool"
                echo "| $name | \`$config\` | [$docs]($docs) |" >> "$tools_file"
            done
            
            log OK "Created TOOLING.md (${#tools_found[@]} tools)"
        fi
    fi
}

# ─── Analyze golden-image vs local ────────────────────────────────────────────

analyze_golden_image() {
    log STEP "Analyzing golden-image alignment..."
    
    local files_to_create=()
    local files_to_replace=()
    local files_ok=()
    
    # Walk golden-image
    while IFS= read -r -d '' golden_file; do
        local relative="${golden_file#$GOLDEN_IMAGE/}"
        local local_file="$REPO_ROOT/$relative"
        
        local status=$(check_file_needed "$golden_file")
        
        case "$status" in
            CREATE)
                files_to_create+=("$relative")
                plan_action "Would create: $relative"
                ;;
            REPLACE)
                files_to_replace+=("$relative")
                plan_action "Would replace: $relative"
                ;;
            OK)
                files_ok+=("$relative")
                ;;
        esac
    done < <(find "$GOLDEN_IMAGE" -type f -print0 2>/dev/null)
    
    PLAN_FILES_CREATED+=("${files_to_create[@]}")
    PLAN_FILES_REPLACED+=("${files_to_replace[@]}")
    
    echo ""
    log INFO "Summary: ${#files_to_create[@]} to create, ${#files_to_replace[@]} to replace, ${#files_ok[@]} OK"
    
    # If applying, do it
    if [[ "$DRY_RUN" == false ]]; then
        for relative in "${files_to_create[@]}"; do
            local golden_file="$GOLDEN_IMAGE/$relative"
            local local_file="$REPO_ROOT/$relative"
            mkdir -p "$(dirname "$local_file")"
            cp "$golden_file" "$local_file"
            log OK "Created: $relative"
        done
        
        for relative in "${files_to_replace[@]}"; do
            local golden_file="$GOLDEN_IMAGE/$relative"
            local local_file="$REPO_ROOT/$relative"
            
            # Backup
            cp "$local_file" "$local_file.bak-$SESSION_ID"
            cp "$golden_file" "$local_file"
            log OK "Replaced: $relative (backup: .bak-$SESSION_ID)"
        done
    fi
}

# ─── Update .gitignore ────────────────────────────────────────────────────────

update_gitignore() {
    local gitignore="$REPO_ROOT/.gitignore"
    local patterns=(
        ".ai/_scratch/"
        "*.plan"
        "tofu.plan"
        "terraform.plan"
        ".terraform/"
        "*.bak-*"
    )
    local added=0
    
    for pattern in "${patterns[@]}"; do
        if ! grep -qxF "$pattern" "$gitignore" 2>/dev/null; then
            if [[ "$DRY_RUN" == true ]]; then
                plan_action "Would add to .gitignore: $pattern"
            else
                echo "$pattern" >> "$gitignore"
            fi
            ((++added))
        fi
    done
    
    [[ $added -gt 0 ]] && log INFO "gitignore: $added patterns to add"
}

# ─── Generate plan document ───────────────────────────────────────────────────

generate_plan_document() {
    mkdir -p "$(dirname "$PLAN_FILE")"
    
    cat > "$PLAN_FILE" << PLAN
# Alignment Plan

**Repository**: \`$REPO_ROOT\`
**Session**: \`$SESSION_ID\`
**Generated**: $(date -Iseconds)

## Summary

| Category | Count |
|----------|-------|
| Files to Create | ${#PLAN_FILES_CREATED[@]} |
| Files to Replace | ${#PLAN_FILES_REPLACED[@]} |
| Actions Planned | ${#PLAN_ACTIONS[@]} |

## Files to Create

$(for f in "${PLAN_FILES_CREATED[@]:-}"; do echo "- \`$f\`"; done)

## Files to Replace

$(for f in "${PLAN_FILES_REPLACED[@]:-}"; do echo "- \`$f\`"; done)

## All Planned Actions

$(for a in "${PLAN_ACTIONS[@]:-}"; do echo "- $a"; done)

---

## Next Steps

Choose one:

\`\`\`bash
# Accept and execute
align-repo.sh --apply

# Defer to GitHub backlog
align-repo.sh --defer

# Discard this plan
align-repo.sh --destroy
\`\`\`
PLAN

    log OK "Generated plan: $PLAN_FILE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# EXECUTE PHASES
# ═══════════════════════════════════════════════════════════════════════════════

discover_tooling
analyze_golden_image
update_gitignore

# ─── Final output ─────────────────────────────────────────────────────────────

echo ""
if [[ "$DRY_RUN" == true ]]; then
    generate_plan_document
    
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║                 DRY-RUN COMPLETE                             ║${NC}"
    echo -e "${YELLOW}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${YELLOW}║  ${#PLAN_FILES_CREATED[@]} files to create                                          ║${NC}"
    echo -e "${YELLOW}║  ${#PLAN_FILES_REPLACED[@]} files to replace                                         ║${NC}"
    echo -e "${YELLOW}║  ${#PLAN_ACTIONS[@]} total actions                                          ║${NC}"
    echo -e "${YELLOW}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${YELLOW}║  Plan: $PLAN_FILE${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo "  align-repo.sh --apply    # Execute this plan"
    echo "  align-repo.sh --defer    # Create backlog issue"
    echo "  align-repo.sh --destroy  # Discard plan"
else
    duration=$(($(date +%s) - START_TIME))
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                 ALIGNMENT COMPLETE                           ║${NC}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║  Duration: ${duration}s                                              ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    
    # Clean up plan files after successful apply
    rm -f "$REPO_ROOT/.ai/_scratch/ALIGNMENT_PLAN"*.md 2>/dev/null || true
    
    # Log to ledger
    ledger="$REPO_ROOT/.ai/ledger/LEDGER.md"
    if [[ -f "$ledger" ]]; then
        cat >> "$ledger" << ENTRY

---
### $(date -Iseconds) - Repo Alignment
**Session**: \`$SESSION_ID\`
**Duration**: ${duration}s
**Files Created**: ${#PLAN_FILES_CREATED[@]}
**Files Replaced**: ${#PLAN_FILES_REPLACED[@]}
ENTRY
    fi
fi
