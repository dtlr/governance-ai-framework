#!/usr/bin/env bash
set -euo pipefail

# align-repo.sh - Complete repo alignment with migration support
#
# Features:
# - Replace conflicts with submodule version (show diffs first)
# - Offer to contribute local rules back to submodule
# - Full documentation links

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

DRY_RUN=false
INTERACTIVE=true  # Default to interactive for migration decisions
SKIP_UPDATE=false
SESSION_ID=$(date +%Y%m%d-%H%M%S)
START_TIME=$(date +%s)

# Track contributions for potential PR
CONTRIBUTIONS_DIR=""
CONTRIBUTIONS=()

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Align repository to governance golden-image with migration support.

Behavior:
- Conflicting files are REPLACED with submodule version
- Diffs are shown before replacement
- You can contribute good local rules back to the submodule

Options:
    --non-interactive   Don't prompt (auto-replace, don't contribute)
    --skip-update       Don't update submodule version
    --dry-run           Preview changes only
    -h, --help          Show this help

Documentation:
    See .governance/ai/README.md for full documentation
    Bundles: .governance/ai/core/templates/golden-image/.ai/bundles/*/RUN.md
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

# Show diff between two files
show_diff() {
    local local_file="$1"
    local global_file="$2"
    local name=$(basename "$local_file")
    
    echo ""
    echo -e "${CYAN}═══ DIFF: $name ═══${NC}"
    echo -e "${RED}--- LOCAL (will be replaced)${NC}"
    echo -e "${GREEN}+++ GLOBAL (from submodule)${NC}"
    echo ""
    
    # Show abbreviated diff
    diff -u "$local_file" "$global_file" 2>/dev/null | head -50 || true
    
    local local_lines=$(wc -l < "$local_file")
    local global_lines=$(wc -l < "$global_file")
    echo ""
    echo "Local: $local_lines lines | Global: $global_lines lines"
}

# Offer to contribute local rule to submodule
offer_contribution() {
    local local_file="$1"
    local name=$(basename "$local_file")
    
    if [[ "$INTERACTIVE" == false ]]; then
        return 0
    fi
    
    echo ""
    echo -e "${YELLOW}This local file has unique content not in global:${NC}"
    echo "  $name"
    echo ""
    read -p "Contribute this to the governance submodule? [y/N]: " contribute
    
    if [[ "$contribute" =~ ^[Yy] ]]; then
        mkdir -p "$CONTRIBUTIONS_DIR"
        cp "$local_file" "$CONTRIBUTIONS_DIR/"
        CONTRIBUTIONS+=("$name")
        log OK "Saved for contribution: $name"
        echo ""
        echo "After alignment, create a PR to governance repo with:"
        echo "  $CONTRIBUTIONS_DIR/$name"
    fi
}

#═══════════════════════════════════════════════════════════════════════════════
# PHASE 1: Submodule Setup
#═══════════════════════════════════════════════════════════════════════════════
setup_submodule() {
    log STEP "Phase 1: Governance Submodule"
    
    local SUBMODULE_PATH=".governance/ai"
    local SUBMODULE_URL="https://github.com/dtlr/governance-ai-framework.git"
    
    cd "$REPO_ROOT"
    
    if [[ -d "$SUBMODULE_PATH/.git" ]] || [[ -f "$SUBMODULE_PATH/.git" ]]; then
        log INFO "Submodule exists"
        
        if [[ "$SKIP_UPDATE" == false ]]; then
            log STEP "Updating to latest..."
            local current=$(cd "$SUBMODULE_PATH" && git describe --tags 2>/dev/null || git rev-parse --short HEAD)
            
            (cd "$SUBMODULE_PATH" && git fetch origin --tags 2>/dev/null)
            local latest=$(cd "$SUBMODULE_PATH" && git describe --tags $(git rev-list --tags --max-count=1) 2>/dev/null || echo "main")
            
            if [[ "$current" != "$latest" ]]; then
                log INFO "Updating: $current → $latest"
                [[ "$DRY_RUN" == false ]] && (cd "$SUBMODULE_PATH" && git checkout "$latest" 2>/dev/null)
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
            (cd "$SUBMODULE_PATH" && git fetch --tags && git checkout $(git describe --tags $(git rev-list --tags --max-count=1) 2>/dev/null || echo "main"))
        }
        log OK "Initialized"
    fi
    
    GOVERNANCE_PATH="$REPO_ROOT/$SUBMODULE_PATH"
    GOLDEN_IMAGE="$GOVERNANCE_PATH/core/templates/golden-image"
    GLOBAL_INFERENCE="$GOVERNANCE_PATH/core/inference-rules"
    CONTRIBUTIONS_DIR="$REPO_ROOT/.ai/_scratch/contributions-$SESSION_ID"
}

#═══════════════════════════════════════════════════════════════════════════════
# PHASE 2: Replace Conflicts with Diffs
#═══════════════════════════════════════════════════════════════════════════════
handle_conflicts() {
    log STEP "Phase 2: Handle Conflicts (replace with submodule)"
    
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
        
        # Skip if local doesn't exist
        [[ ! -f "$full_local" ]] && continue
        [[ ! -f "$global_path" ]] && continue
        
        # Compare
        if ! diff -q "$full_local" "$global_path" &>/dev/null; then
            log DIFF "Conflict: $local_path"
            
            if [[ "$INTERACTIVE" == true ]]; then
                show_diff "$full_local" "$global_path"
                echo ""
                read -p "Replace with submodule version? [Y/n]: " replace
                replace=${replace:-Y}
            else
                replace="Y"
            fi
            
            if [[ "$replace" =~ ^[Yy] ]]; then
                if [[ "$DRY_RUN" == false ]]; then
                    # Backup local
                    cp "$full_local" "$full_local.backup-$SESSION_ID"
                    cp "$global_path" "$full_local"
                fi
                log OK "Replaced: $local_path (backup: .backup-$SESSION_ID)"
                ((replaced++))
            else
                log WARN "Skipped: $local_path"
                ((skipped++))
            fi
        fi
    done
    
    log INFO "Replaced: $replaced, Skipped: $skipped"
}

#═══════════════════════════════════════════════════════════════════════════════
# PHASE 3: Inference Migration
#═══════════════════════════════════════════════════════════════════════════════
migrate_inference() {
    log STEP "Phase 3: Inference Migration"
    
    local LOCAL_INFERENCE="$REPO_ROOT/.ai/inference"
    local deleted=0
    local contributed=0
    
    mkdir -p "$LOCAL_INFERENCE"
    
    # Check each local inference file
    for local_file in "$LOCAL_INFERENCE"/*.md; do
        [[ ! -f "$local_file" ]] && continue
        [[ "$(basename "$local_file")" == "README.md" ]] && continue
        
        local filename=$(basename "$local_file")
        local global_file="$GLOBAL_INFERENCE/$filename"
        
        if [[ -f "$global_file" ]]; then
            # Global exists - compare
            if diff -q "$local_file" "$global_file" &>/dev/null; then
                # Exact match - delete local
                log INFO "Duplicate: $filename → deleting (use global)"
                [[ "$DRY_RUN" == false ]] && rm "$local_file"
                ((deleted++))
            else
                # Different - show diff, replace, offer to contribute
                log DIFF "Differs: $filename"
                
                if [[ "$INTERACTIVE" == true ]]; then
                    show_diff "$local_file" "$global_file"
                fi
                
                # Offer to contribute before replacing
                offer_contribution "$local_file"
                
                # Replace with global
                if [[ "$DRY_RUN" == false ]]; then
                    rm "$local_file"
                fi
                log OK "Removed local (use global): $filename"
                ((deleted++))
            fi
        else
            # No global equivalent - this is unique
            log INFO "Unique local rule: $filename"
            
            if [[ "$INTERACTIVE" == true ]]; then
                echo ""
                echo -e "${YELLOW}This rule doesn't exist in global. Options:${NC}"
                echo "  1) Keep locally (repo-specific)"
                echo "  2) Contribute to submodule (for all repos)"
                echo "  3) Delete (not needed)"
                read -p "Choice [1/2/3]: " choice
                
                case "$choice" in
                    2)
                        mkdir -p "$CONTRIBUTIONS_DIR"
                        cp "$local_file" "$CONTRIBUTIONS_DIR/"
                        CONTRIBUTIONS+=("$filename")
                        log OK "Saved for contribution"
                        ((contributed++))
                        ;;
                    3)
                        [[ "$DRY_RUN" == false ]] && rm "$local_file"
                        log OK "Deleted"
                        ((deleted++))
                        ;;
                    *)
                        log INFO "Keeping locally"
                        ;;
                esac
            fi
        fi
    done
    
    # Generate README
    [[ "$DRY_RUN" == false ]] && cat > "$LOCAL_INFERENCE/README.md" << EOF
# Inference Rules

## Global Rules (from governance submodule)

Use rules from \`.governance/ai/core/inference-rules/\`:

| Rule | Description | Docs |
|------|-------------|------|
$(for f in "$GLOBAL_INFERENCE"/*.md; do
    [[ "$(basename "$f")" == "README.md" ]] && continue
    name=$(basename "$f" .md)
    echo "| [$name](.governance/ai/core/inference-rules/$name.md) | See file | [Link](.governance/ai/core/inference-rules/$name.md) |"
done)

## Local Rules (repo-specific only)

$(ls "$LOCAL_INFERENCE"/*.md 2>/dev/null | grep -v README.md | while read f; do
    echo "- $(basename "$f")"
done || echo "*None - all rules are global*")

---
*Generated by align-repo.sh ($SESSION_ID)*
EOF

    log INFO "Deleted: $deleted, Contributions: ${#CONTRIBUTIONS[@]}"
}

#═══════════════════════════════════════════════════════════════════════════════
# PHASE 4: Create Missing Files
#═══════════════════════════════════════════════════════════════════════════════
create_missing() {
    log STEP "Phase 4: Create Missing Files"
    
    local created=0
    
    # Directories
    mkdir -p "$REPO_ROOT/.governance"
    mkdir -p "$REPO_ROOT/.governance-local"
    mkdir -p "$REPO_ROOT/.ai/ledger"
    mkdir -p "$REPO_ROOT/.ai/_scratch"
    mkdir -p "$REPO_ROOT/.ai/inference"
    mkdir -p "$REPO_ROOT/.ai/bundles"
    mkdir -p "$REPO_ROOT/docs/_shared"
    
    # Copy missing files from golden-image
    declare -A FILES_TO_CREATE=(
        [".governance/manifest.json"]="$GOLDEN_IMAGE/.governance/manifest.json"
        [".governance-local/overrides.yaml"]="$GOLDEN_IMAGE/.governance-local/overrides.yaml"
        ["CLAUDE.md"]="$GOLDEN_IMAGE/CLAUDE.md"
        [".ai/ledger/LEDGER.md"]="$GOLDEN_IMAGE/.ai/ledger/LEDGER.md"
        [".ai/ledger/PLANNING.md"]="$GOLDEN_IMAGE/.ai/ledger/PLANNING.md"
        [".ai/ledger/EFFICIENCY.md"]="$GOLDEN_IMAGE/.ai/ledger/EFFICIENCY.md"
        ["docs/_shared/router.md"]="$GOLDEN_IMAGE/docs/_shared/router.md"
    )
    
    for target in "${!FILES_TO_CREATE[@]}"; do
        local source="${FILES_TO_CREATE[$target]}"
        local full_target="$REPO_ROOT/$target"
        
        if [[ ! -f "$full_target" ]] && [[ -f "$source" ]]; then
            [[ "$DRY_RUN" == false ]] && cp "$source" "$full_target"
            log OK "Created: $target"
            ((created++))
        fi
    done
    
    # Scratch gitignore
    if [[ ! -f "$REPO_ROOT/.ai/_scratch/.gitignore" ]]; then
        [[ "$DRY_RUN" == false ]] && echo -e "*\n!.gitignore" > "$REPO_ROOT/.ai/_scratch/.gitignore"
        log OK "Created: .ai/_scratch/.gitignore"
        ((created++))
    fi
    
    log INFO "Created: $created files"
}

#═══════════════════════════════════════════════════════════════════════════════
# PHASE 5: Generate Documentation
#═══════════════════════════════════════════════════════════════════════════════
generate_docs() {
    log STEP "Phase 5: Generate Documentation Pointers"
    
    [[ "$DRY_RUN" == true ]] && return 0
    
    # Simple .ai/README.md pointing to submodule
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
| `_scratch/` | Ephemeral (gitignored) |
HEREDOC
    
    log OK "Created: .ai/README.md (points to submodule)"
}

#═══════════════════════════════════════════════════════════════════════════════
# PHASE 6: Summary
#═══════════════════════════════════════════════════════════════════════════════
print_summary() {
    local duration=$(($(date +%s) - START_TIME))
    
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           ALIGNMENT COMPLETE                                 ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Session:  $SESSION_ID"
    echo "Duration: ${duration}s"
    echo ""
    
    if [[ ${#CONTRIBUTIONS[@]} -gt 0 ]]; then
        echo -e "${YELLOW}═══ CONTRIBUTIONS TO SUBMIT ═══${NC}"
        echo "You offered to contribute these rules to the governance submodule:"
        for c in "${CONTRIBUTIONS[@]}"; do
            echo "  - $c"
        done
        echo ""
        echo "To submit:"
        echo "  1. cd .governance/ai"
        echo "  2. git checkout -b contribute-$SESSION_ID"
        echo "  3. cp $CONTRIBUTIONS_DIR/*.md core/inference-rules/"
        echo "  4. git add . && git commit -m 'feat: Add inference rules from migration'"
        echo "  5. git push && create PR"
        echo ""
    fi
    
    echo "Documentation: .ai/DOCUMENTATION.md"
    echo ""
    echo "Next steps:"
    echo "  1. Review & customize CLAUDE.md"
    echo "  2. Update docs/_shared/router.md for your repo"
    echo "  3. git add . && git commit -m 'feat: Align to governance'"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --non-interactive) INTERACTIVE=false; shift ;;
        --skip-update) SKIP_UPDATE=true; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown: $1"; usage ;;
    esac
done

# Header
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       Repository Alignment (Migration Mode)                  ║${NC}"
echo -e "${BLUE}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BLUE}║  Conflicts will be REPLACED with submodule version          ║${NC}"
echo -e "${BLUE}║  You can contribute good local rules back to submodule      ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Run phases
setup_submodule
handle_conflicts
migrate_inference
create_missing
discover_tooling
generate_docs
print_summary

#═══════════════════════════════════════════════════════════════════════════════
# PHASE 6: Tooling Discovery
#═══════════════════════════════════════════════════════════════════════════════
discover_tooling() {
    log STEP "Phase 6: Tooling Discovery"
    
    [[ "$DRY_RUN" == true ]] && { log INFO "Dry run - skipping tooling scan"; return 0; }
    
    local TOOLING_FILE="$REPO_ROOT/.ai/TOOLING.md"
    
    # Tool detection map: config_pattern|tool_name|docs_url
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
        
        # Check for pattern
        if [[ "$pattern" == *"*"* ]]; then
            found=$(find . -maxdepth 4 -name "$pattern" -not -path "./.governance/*" -not -path "./node_modules/*" 2>/dev/null | head -3)
        elif [[ "$pattern" == *"/" ]]; then
            [[ -d "$pattern" ]] && found="$pattern"
        else
            [[ -f "$pattern" ]] && found="$pattern"
        fi
        
        if [[ -n "$found" ]]; then
            local first_match=$(echo "$found" | head -1)
            detected+=("$name|$first_match|$docs")
            
            # Build details section
            detected_details+="### $name\n"
            detected_details+="- **Config**: \`$first_match\`\n"
            detected_details+="- **Docs**: $docs\n"
            
            # Special handling for known integrations
            if [[ "$name" == "direnv" ]] && grep -q "op://" "$first_match" 2>/dev/null; then
                detected_details+="- **Integrations**: 1Password CLI ([Docs](https://developer.1password.com/docs/cli))\n"
            fi
            detected_details+="\n"
            
            log OK "Found: $name ($first_match)"
        fi
    done
    
    # Generate TOOLING.md
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
