#!/usr/bin/env bash
set -euo pipefail

# align-repo.sh - Portable repo alignment script
#
# Can be called from any repository. Works on the CURRENT directory,
# not where this script lives.
#
# Usage:
#   /path/to/align-repo.sh                    # Align current repo
#   /path/to/align-repo.sh --target /other    # Align specific repo
#   /path/to/align-repo.sh --dry-run          # Preview only

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Defaults
DRY_RUN=false
INTERACTIVE=true
SKIP_UPDATE=false
TARGET_DIR=""
SESSION_ID=$(date +%Y%m%d-%H%M%S)
START_TIME=$(date +%s)

# Track contributions
CONTRIBUTIONS_DIR=""
CONTRIBUTIONS=()

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Portable repo alignment - works on ANY repository.

Options:
    --target <dir>      Align a specific directory (default: current dir)
    --non-interactive   Don't prompt (auto-replace, don't contribute)
    --skip-update       Don't update submodule version
    --dry-run           Preview changes only
    -h, --help          Show this help

Examples:
    # From any directory, align current repo
    /path/to/align-repo.sh
    
    # Align a different repo
    /path/to/align-repo.sh --target ~/work/other-repo
    
    # Add to PATH for convenience
    export PATH="\$PATH:/path/to/governance/core/automation"
    align-repo.sh  # Now works anywhere

Documentation:
    See .governance/ai/README.md after alignment
EOF
    exit 0
}

log() {
    local level="$1"; shift
    case "$level" in
        INFO)  echo -e "${BLUE}ℹ${NC} $*" ;;
        OK)    echo -e "${GREEN}✓${NC} $*" ;;
        WARN)  echo -e "${YELLOW}⚠${NC} $*" ;;
        ERROR) echo -e "${RED}✗${NC} $*" ;;
        STEP)  echo -e "${MAGENTA}→${NC} $*" ;;
        DIFF)  echo -e "${CYAN}≠${NC} $*" ;;
    esac
}

show_diff() {
    local local_file="$1"
    local global_file="$2"
    local name=$(basename "$local_file")
    
    echo ""
    echo -e "${CYAN}═══ DIFF: $name ═══${NC}"
    echo -e "${RED}--- LOCAL (will be replaced)${NC}"
    echo -e "${GREEN}+++ GLOBAL (from submodule)${NC}"
    echo ""
    diff -u "$local_file" "$global_file" 2>/dev/null | head -50 || true
    echo ""
}

offer_contribution() {
    local local_file="$1"
    local name=$(basename "$local_file")
    
    [[ "$INTERACTIVE" == false ]] && return 0
    
    echo ""
    echo -e "${YELLOW}This local file has unique content not in global:${NC}"
    echo "  $name"
    read -p "Contribute this to the governance submodule? [y/N]: " contribute
    
    if [[ "$contribute" =~ ^[Yy] ]]; then
        mkdir -p "$CONTRIBUTIONS_DIR"
        cp "$local_file" "$CONTRIBUTIONS_DIR/"
        CONTRIBUTIONS+=("$name")
        log OK "Saved for contribution: $name"
    fi
}

#═══════════════════════════════════════════════════════════════════════════════
# PHASE 0: Determine Target Repository
#═══════════════════════════════════════════════════════════════════════════════
determine_target() {
    log STEP "Phase 0: Determine Target Repository"
    
    if [[ -n "$TARGET_DIR" ]]; then
        # Explicit target provided
        if [[ ! -d "$TARGET_DIR" ]]; then
            log ERROR "Target directory does not exist: $TARGET_DIR"
            exit 1
        fi
        REPO_ROOT="$(cd "$TARGET_DIR" && git rev-parse --show-toplevel 2>/dev/null || echo "$TARGET_DIR")"
    else
        # Use current working directory
        REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
    fi
    
    log INFO "Target repo: $REPO_ROOT"
    
    # Verify it's a git repo
    if ! git -C "$REPO_ROOT" rev-parse --git-dir &>/dev/null; then
        log WARN "Not a git repository. Proceeding anyway..."
    fi
    
    cd "$REPO_ROOT"
    CONTRIBUTIONS_DIR="$REPO_ROOT/.ai/_scratch/contributions-$SESSION_ID"
}

#═══════════════════════════════════════════════════════════════════════════════
# PHASE 1: Read Existing References
#═══════════════════════════════════════════════════════════════════════════════
read_existing_references() {
    shopt -s nullglob globstar 2>/dev/null || true
    log STEP "Phase 1: Read Existing References"
    
    # Track existing file references that need updating
    declare -gA EXISTING_REFS=()
    
    # Check .gitignore for patterns we need to preserve
    if [[ -f "$REPO_ROOT/.gitignore" ]]; then
        log INFO "Reading .gitignore patterns"
        EXISTING_REFS[".gitignore"]="exists"
    fi
    
    # Check for existing CLAUDE.md references
    if [[ -f "$REPO_ROOT/CLAUDE.md" ]]; then
        log INFO "Found existing CLAUDE.md"
        EXISTING_REFS["CLAUDE.md"]="exists"
        
        # Extract any file references from CLAUDE.md
        local refs=$(grep -oE '\`[^`]+\.(md|sh|json|yaml|yml)\`' "$REPO_ROOT/CLAUDE.md" 2>/dev/null | tr -d '`' | sort -u || true)
        if [[ -n "$refs" ]]; then
            log INFO "Found $(echo "$refs" | wc -l) file references in CLAUDE.md"
        fi
    fi
    
    # Check for existing router.md
    if [[ -f "$REPO_ROOT/docs/_shared/router.md" ]]; then
        log INFO "Found existing router.md"
        EXISTING_REFS["router.md"]="exists"
    fi
    
    # Check existing .ai structure
    if [[ -d "$REPO_ROOT/.ai" ]]; then
        log INFO "Found existing .ai/ structure"
        for f in "$REPO_ROOT/.ai"/**/*.md; do
            [[ -f "$f" ]] && EXISTING_REFS["${f#$REPO_ROOT/}"]="exists"
        done
    fi
    
    log INFO "Tracked ${#EXISTING_REFS[@]} existing references"
}

#═══════════════════════════════════════════════════════════════════════════════
# PHASE 2: Governance Submodule Setup
#═══════════════════════════════════════════════════════════════════════════════
setup_submodule() {
    log STEP "Phase 2: Governance Submodule"
    
    local SUBMODULE_PATH=".governance/ai"
    local SUBMODULE_URL="https://github.com/dtlr/governance-ai-framework.git"
    
    cd "$REPO_ROOT"
    
    if [[ -d "$SUBMODULE_PATH/.git" ]] || [[ -f "$SUBMODULE_PATH/.git" ]]; then
        log INFO "Submodule exists"
        
        if [[ "$SKIP_UPDATE" == false ]]; then
            log INFO "Checking for updates..."
            local current=$(cd "$SUBMODULE_PATH" && git describe --tags 2>/dev/null || git rev-parse --short HEAD)
            
            (cd "$SUBMODULE_PATH" && git fetch origin --tags 2>/dev/null) || true
            local latest=$(cd "$SUBMODULE_PATH" && git describe --tags $(git rev-list --tags --max-count=1) 2>/dev/null || echo "main")
            
            if [[ "$current" != "$latest" ]]; then
                log INFO "Updating: $current → $latest"
                [[ "$DRY_RUN" == false ]] && (cd "$SUBMODULE_PATH" && git checkout "$latest" 2>/dev/null) || true
            else
                log INFO "Already at latest: $current"
            fi
        fi
    else
        log WARN "Submodule not found. Initializing..."
        [[ "$DRY_RUN" == false ]] && {
            if grep -q "governance-ai" .gitmodules 2>/dev/null; then
                git submodule update --init "$SUBMODULE_PATH"
            else
                git submodule add "$SUBMODULE_URL" "$SUBMODULE_PATH"
            fi
            (cd "$SUBMODULE_PATH" && git fetch --tags && git checkout $(git describe --tags $(git rev-list --tags --max-count=1) 2>/dev/null || echo "main")) || true
        }
        log OK "Initialized"
    fi
    
    GOVERNANCE_PATH="$REPO_ROOT/$SUBMODULE_PATH"
    GOLDEN_IMAGE="$GOVERNANCE_PATH/core/templates/golden-image"
    GLOBAL_INFERENCE="$GOVERNANCE_PATH/core/inference-rules"
}

#═══════════════════════════════════════════════════════════════════════════════
# PHASE 3: Handle Conflicts (Replace with Submodule)
#═══════════════════════════════════════════════════════════════════════════════
handle_conflicts() {
    log STEP "Phase 3: Handle Conflicts (replace with submodule)"
    
    local replaced=0
    local skipped=0
    
    # Files that should match golden-image exactly
    declare -A MANAGED_FILES=(
        [".governance/manifest.json"]="$GOLDEN_IMAGE/.governance/manifest.json"
        [".governance/DIRECTORY_CONTRACT.md"]="$GOLDEN_IMAGE/.governance/DIRECTORY_CONTRACT.md"
        [".ai/ledger/EFFICIENCY.md"]="$GOLDEN_IMAGE/.ai/ledger/EFFICIENCY.md"
    )
    
    for local_path in "${!MANAGED_FILES[@]}"; do
        local global_path="${MANAGED_FILES[$local_path]}"
        local full_local="$REPO_ROOT/$local_path"
        
        [[ ! -f "$full_local" ]] && continue
        [[ ! -f "$global_path" ]] && continue
        
        if ! diff -q "$full_local" "$global_path" &>/dev/null; then
            log DIFF "Conflict: $local_path"
            
            if [[ "$INTERACTIVE" == true ]]; then
                show_diff "$full_local" "$global_path"
                read -p "Replace with submodule version? [Y/n]: " replace
                replace=${replace:-Y}
            else
                replace="Y"
            fi
            
            if [[ "$replace" =~ ^[Yy] ]]; then
                if [[ "$DRY_RUN" == false ]]; then
                    cp "$full_local" "$full_local.backup-$SESSION_ID"
                    cp "$global_path" "$full_local"
                fi
                log OK "Replaced: $local_path (backup: .backup-$SESSION_ID)"
                ((++replaced))
            else
                log WARN "Skipped: $local_path"
                ((++skipped))
            fi
        fi
    done
    
    log INFO "Replaced: $replaced, Skipped: $skipped"
}

#═══════════════════════════════════════════════════════════════════════════════
# PHASE 4: Inference Migration
#═══════════════════════════════════════════════════════════════════════════════
migrate_inference() {
    log STEP "Phase 4: Inference Migration"
    
    local LOCAL_INFERENCE="$REPO_ROOT/.ai/inference"
    local deleted=0
    
    mkdir -p "$LOCAL_INFERENCE"
    
    for local_file in "$LOCAL_INFERENCE"/*.md; do
        [[ ! -f "$local_file" ]] && continue
        [[ "$(basename "$local_file")" == "README.md" ]] && continue
        
        local filename=$(basename "$local_file")
        local global_file="$GLOBAL_INFERENCE/$filename"
        
        if [[ -f "$global_file" ]]; then
            if diff -q "$local_file" "$global_file" &>/dev/null; then
                log INFO "Duplicate: $filename → deleting (use global)"
                [[ "$DRY_RUN" == false ]] && rm "$local_file"
                ((++deleted))
            else
                log DIFF "Differs: $filename"
                [[ "$INTERACTIVE" == true ]] && show_diff "$local_file" "$global_file"
                offer_contribution "$local_file"
                [[ "$DRY_RUN" == false ]] && rm "$local_file"
                log OK "Removed local (use global): $filename"
                ((++deleted))
            fi
        else
            log INFO "Unique local rule: $filename (keeping)"
        fi
    done
    
    # Generate inference README
    [[ "$DRY_RUN" == false ]] && cat > "$LOCAL_INFERENCE/README.md" << EOF
# Inference Rules

## Global Rules (from governance submodule)

See: \`.governance/ai/core/inference-rules/\`

## Local Rules (repo-specific)

$(ls "$LOCAL_INFERENCE"/*.md 2>/dev/null | grep -v README.md | while read f; do
    echo "- $(basename "$f")"
done || echo "*None - all rules are global*")

---
*Generated by align-repo.sh ($SESSION_ID)*
EOF

    log INFO "Deleted: $deleted duplicates, Contributions: ${#CONTRIBUTIONS[@]}"
}

#═══════════════════════════════════════════════════════════════════════════════
# PHASE 5: Create Missing Files
#═══════════════════════════════════════════════════════════════════════════════
create_missing() {
    log STEP "Phase 5: Create Missing Files"
    
    local created=0
    
    # Create directories
    mkdir -p "$REPO_ROOT/.governance"
    mkdir -p "$REPO_ROOT/.governance-local"
    mkdir -p "$REPO_ROOT/.ai/ledger"
    mkdir -p "$REPO_ROOT/.ai/_scratch"
    mkdir -p "$REPO_ROOT/.ai/inference"
    mkdir -p "$REPO_ROOT/.ai/bundles"
    mkdir -p "$REPO_ROOT/docs/_shared"
    
    # Files to copy from golden-image (only if missing)
    declare -A FILES_TO_CREATE=(
        [".governance/manifest.json"]="$GOLDEN_IMAGE/.governance/manifest.json"
        [".governance-local/overrides.yaml"]="$GOLDEN_IMAGE/.governance-local/overrides.yaml"
        [".ai/ledger/LEDGER.md"]="$GOLDEN_IMAGE/.ai/ledger/LEDGER.md"
        [".ai/ledger/PLANNING.md"]="$GOLDEN_IMAGE/.ai/ledger/PLANNING.md"
        [".ai/ledger/EFFICIENCY.md"]="$GOLDEN_IMAGE/.ai/ledger/EFFICIENCY.md"
    )
    
    for target in "${!FILES_TO_CREATE[@]}"; do
        local source="${FILES_TO_CREATE[$target]}"
        local full_target="$REPO_ROOT/$target"
        
        if [[ ! -f "$full_target" ]] && [[ -f "$source" ]]; then
            [[ "$DRY_RUN" == false ]] && cp "$source" "$full_target"
            log OK "Created: $target"
            ((++created))
        fi
    done
    
    # Scratch gitignore
    if [[ ! -f "$REPO_ROOT/.ai/_scratch/.gitignore" ]]; then
        [[ "$DRY_RUN" == false ]] && echo -e "*\n!.gitignore" > "$REPO_ROOT/.ai/_scratch/.gitignore"
        log OK "Created: .ai/_scratch/.gitignore"
        ((++created))
    fi
    
    log INFO "Created: $created files"
}

#═══════════════════════════════════════════════════════════════════════════════
# PHASE 6: Tooling Discovery
#═══════════════════════════════════════════════════════════════════════════════
discover_tooling() {
    log STEP "Phase 6: Tooling Discovery"
    
    [[ "$DRY_RUN" == true ]] && { log INFO "Dry run - skipping tooling scan"; return 0; }
    
    local TOOLING_FILE="$REPO_ROOT/.ai/TOOLING.md"
    
    declare -a TOOLS=(
        ".editorconfig|EditorConfig|https://editorconfig.org"
        ".envrc|direnv|https://direnv.net"
        "*.tf|OpenTofu|https://opentofu.org/docs"
        "Chart.yaml|Helm|https://helm.sh/docs"
        "kustomization.yaml|Kustomize|https://kustomize.io"
        ".github/workflows/*.yml|GitHub Actions|https://docs.github.com/actions"
        "Makefile|Make|https://www.gnu.org/software/make/manual"
        "*.pkr.hcl|Packer|https://developer.hashicorp.com/packer/docs"
        ".claude/|Claude Code|https://docs.anthropic.com/claude-code"
        ".vscode/|VSCode|https://code.visualstudio.com/docs"
        ".eslintrc*|ESLint|https://eslint.org/docs"
        ".prettierrc*|Prettier|https://prettier.io/docs"
        "biome.json|Biome|https://biomejs.dev/reference"
        "tsconfig.json|TypeScript|https://typescriptlang.org/docs"
        ".mise.toml|mise|https://mise.jdx.dev"
        ".tool-versions|asdf|https://asdf-vm.com/guide"
        ".pre-commit-config.yaml|pre-commit|https://pre-commit.com"
        "lefthook.yml|lefthook|https://github.com/evilmartians/lefthook"
        "ansible.cfg|Ansible|https://docs.ansible.com"
        ".ansible/|Ansible|https://docs.ansible.com"
        "package.json|Node.js/npm|https://docs.npmjs.com"
        "pyproject.toml|Python/Poetry|https://python-poetry.org/docs"
        "requirements.txt|Python/pip|https://pip.pypa.io/en/stable"
        "go.mod|Go|https://go.dev/doc"
        "Cargo.toml|Rust|https://doc.rust-lang.org/cargo"
        "docker-compose*.yml|Docker Compose|https://docs.docker.com/compose"
        "Dockerfile|Docker|https://docs.docker.com/reference/dockerfile"
    )
    
    local detected=()
    local detected_details=""
    
    cd "$REPO_ROOT"
    
    for tool_entry in "${TOOLS[@]}"; do
        IFS='|' read -r pattern name docs <<< "$tool_entry"
        local found=""
        
        if [[ "$pattern" == *"*"* ]]; then
            if [[ "$pattern" == ".github/workflows/"* ]]; then
                found=$(find .github/workflows -maxdepth 1 \( -name "*.yml" -o -name "*.yaml" \) 2>/dev/null | head -1)
            else
                found=$(find . -maxdepth 5 -name "${pattern##*/}" -not -path "./.governance/*" -not -path "./node_modules/*" 2>/dev/null | head -1)
            fi
        elif [[ "$pattern" == *"/" ]]; then
            [[ -d "$pattern" ]] && found="$pattern"
        else
            if [[ -f "$pattern" ]]; then
                found="$pattern"
            else
                found=$(find . -maxdepth 5 -name "$pattern" -not -path "./.governance/*" -not -path "./node_modules/*" 2>/dev/null | head -1)
            fi
        fi
        
        if [[ -n "$found" ]]; then
            local first_match=$(echo "$found" | head -1)
            detected+=("$name|$first_match|$docs")
            
            detected_details+="### $name\n"
            detected_details+="- **Config**: \`$first_match\`\n"
            detected_details+="- **Docs**: $docs\n"
            
            if [[ "$name" == "direnv" ]] && grep -q "op://" "$first_match" 2>/dev/null; then
                detected_details+="- **Integrations**: 1Password CLI ([Docs](https://developer.1password.com/docs/cli))\n"
            fi
            detected_details+="\n"
            
            log OK "Found: $name ($first_match)"
        fi
    done
    
    cat > "$TOOLING_FILE" << TOOLINGHEADER
# Repository Tooling

*Auto-generated by align-repo.sh ($SESSION_ID)*

## Detected Tools

| Tool | Config | Docs |
|------|--------|------|
TOOLINGHEADER

    for entry in "${detected[@]}"; do
        IFS='|' read -r name config docs <<< "$entry"
        echo "| $name | \`$config\` | [Docs]($docs) |" >> "$TOOLING_FILE"
    done

    echo -e "\n## Tool Details\n" >> "$TOOLING_FILE"
    echo -e "$detected_details" >> "$TOOLING_FILE"
    
    log OK "Created: .ai/TOOLING.md (${#detected[@]} tools)"
}

#═══════════════════════════════════════════════════════════════════════════════
# PHASE 7: Update .gitignore
#═══════════════════════════════════════════════════════════════════════════════
update_gitignore() {
    log STEP "Phase 7: Update .gitignore"
    
    local GITIGNORE="$REPO_ROOT/.gitignore"
    local patterns=(
        ".ai/_scratch/"
        ".governance-local/"
        "*.backup-*"
        "tofu.plan"
        ".terraform/"
        ".terraform.lock.hcl"
    )
    
    local added=0
    
    for pattern in "${patterns[@]}"; do
        if ! grep -qF "$pattern" "$GITIGNORE" 2>/dev/null; then
            [[ "$DRY_RUN" == false ]] && echo "$pattern" >> "$GITIGNORE"
            log OK "Added to .gitignore: $pattern"
            ((++added))
        fi
    done
    
    log INFO "Added $added patterns to .gitignore"
}

#═══════════════════════════════════════════════════════════════════════════════
# PHASE 8: Generate Documentation Pointers
#═══════════════════════════════════════════════════════════════════════════════
generate_docs() {
    log STEP "Phase 8: Generate Documentation Pointers"
    
    [[ "$DRY_RUN" == true ]] && return 0
    
    cat > "$REPO_ROOT/.ai/README.md" << 'HEREDOC'
# AI Artifacts

## Global Resources (Submodule)

All documentation, inference rules, and bundles are in the governance submodule:

| Resource | Location |
|----------|----------|
| Inference Rules | `.governance/ai/core/inference-rules/` |
| Bundles | `.governance/ai/core/templates/golden-image/.ai/bundles/` |
| Automation | `.governance/ai/core/automation/` |
| Full Docs | `.governance/ai/README.md` |

## Quick Commands

```bash
# Align repo
.governance/ai/core/automation/align-repo.sh

# Plan feature
.governance/ai/core/automation/plan-feature.sh --request "..."

# Research
.governance/ai/core/automation/plan-feature.sh --research --question "..."
```

## Local Files

| File | Purpose |
|------|---------|
| `ledger/LEDGER.md` | Implementation operations |
| `ledger/PLANNING.md` | Planning sessions |
| `inference/*.md` | Repo-specific rules only |
| `TOOLING.md` | Auto-detected tooling |
| `_scratch/` | Ephemeral (gitignored) |
HEREDOC
    
    log OK "Created: .ai/README.md (points to submodule)"
}

#═══════════════════════════════════════════════════════════════════════════════
# Summary
#═══════════════════════════════════════════════════════════════════════════════
print_summary() {
    local duration=$(($(date +%s) - START_TIME))
    
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           ALIGNMENT COMPLETE                                 ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Repository: $REPO_ROOT"
    echo "Session:    $SESSION_ID"
    echo "Duration:   ${duration}s"
    echo ""
    
    if [[ ${#CONTRIBUTIONS[@]} -gt 0 ]]; then
        echo -e "${YELLOW}═══ CONTRIBUTIONS TO SUBMIT ═══${NC}"
        echo "You offered to contribute:"
        for c in "${CONTRIBUTIONS[@]}"; do
            echo "  - $c"
        done
        echo ""
        echo "To submit:"
        echo "  1. cd $REPO_ROOT/.governance/ai"
        echo "  2. git checkout -b contribute-$SESSION_ID"
        echo "  3. cp $CONTRIBUTIONS_DIR/*.md core/inference-rules/"
        echo "  4. git push && create PR"
        echo ""
    fi
    
    echo "Next steps:"
    echo "  1. Review & customize CLAUDE.md (if you have one)"
    echo "  2. Create/update docs/_shared/router.md for your repo"
    echo "  3. git add . && git commit -m 'feat: Align to governance'"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --target) TARGET_DIR="$2"; shift 2 ;;
        --non-interactive) INTERACTIVE=false; shift ;;
        --skip-update) SKIP_UPDATE=true; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown: $1"; usage ;;
    esac
done

# Header
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       Repository Alignment (Portable)                        ║${NC}"
echo -e "${BLUE}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BLUE}║  Works on ANY repo - uses current directory by default      ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Run phases
determine_target
read_existing_references
setup_submodule
handle_conflicts
migrate_inference
create_missing
discover_tooling
update_gitignore
generate_docs
print_summary
