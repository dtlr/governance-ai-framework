#!/usr/bin/env bash
set -euo pipefail

# align-repo.sh - Complete repo alignment to governance golden-image
#
# Features:
# 1. Auto-update submodule to latest version
# 2. Add missing governance structure
# 3. Deduplicate inference (local vs global)
# 4. Repo-agnostic (works on any repo)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

DRY_RUN=false
INTERACTIVE=false
SKIP_UPDATE=false
SESSION_ID=$(date +%Y%m%d-%H%M%S)
START_TIME=$(date +%s)

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Align any repository to the governance golden-image structure.

This script is REPO-AGNOSTIC and will:
1. Initialize or update governance submodule to latest version
2. Compare repo against golden-image template
3. Add missing governance files
4. Deduplicate local inference rules (remove duplicates of global rules)
5. Generate repo-specific router.md

Options:
    --skip-update       Don't update submodule (use current version)
    --dry-run           Show what would be done
    --interactive       Confirm each step
    -h, --help          Show this help

Examples:
    # Full alignment (recommended)
    $(basename "$0")
    
    # Skip submodule update
    $(basename "$0") --skip-update
    
    # See what would happen
    $(basename "$0") --dry-run
EOF
    exit 0
}

# Log function
log() {
    local level="$1"
    shift
    case "$level" in
        INFO)  echo -e "${BLUE}ℹ${NC} $*" ;;
        OK)    echo -e "${GREEN}✓${NC} $*" ;;
        WARN)  echo -e "${YELLOW}⚠${NC} $*" ;;
        ERROR) echo -e "${RED}✗${NC} $*" ;;
        STEP)  echo -e "${MAGENTA}→${NC} $*" ;;
    esac
}

# Check if command exists
has_cmd() {
    command -v "$1" &> /dev/null
}

#═══════════════════════════════════════════════════════════════════════════════
# PHASE 1: Submodule Management
#═══════════════════════════════════════════════════════════════════════════════
setup_submodule() {
    log STEP "Phase 1: Governance Submodule"
    
    local SUBMODULE_PATH=".governance/ai"
    local SUBMODULE_URL="https://github.com/dtlr/governance-ai-framework.git"
    
    cd "$REPO_ROOT"
    
    # Check if submodule exists
    if [[ -d "$SUBMODULE_PATH/.git" ]] || [[ -f "$SUBMODULE_PATH/.git" ]]; then
        log INFO "Submodule exists at $SUBMODULE_PATH"
        
        if [[ "$SKIP_UPDATE" == false ]]; then
            log STEP "Updating to latest version..."
            
            # Get current version
            local current_version=$(cd "$SUBMODULE_PATH" && git describe --tags 2>/dev/null || git rev-parse --short HEAD)
            log INFO "Current: $current_version"
            
            # Fetch and update
            (cd "$SUBMODULE_PATH" && git fetch origin --tags)
            local latest_tag=$(cd "$SUBMODULE_PATH" && git describe --tags $(git rev-list --tags --max-count=1) 2>/dev/null || echo "main")
            
            if [[ "$DRY_RUN" == true ]]; then
                log INFO "Would update to: $latest_tag"
            else
                (cd "$SUBMODULE_PATH" && git checkout "$latest_tag" 2>/dev/null || git checkout main)
                local new_version=$(cd "$SUBMODULE_PATH" && git describe --tags 2>/dev/null || git rev-parse --short HEAD)
                log OK "Updated to: $new_version"
            fi
        else
            log INFO "Skipping update (--skip-update)"
        fi
    else
        log WARN "Submodule not found. Initializing..."
        
        if [[ "$DRY_RUN" == true ]]; then
            log INFO "Would run: git submodule add $SUBMODULE_URL $SUBMODULE_PATH"
        else
            # Check if .gitmodules entry exists but submodule not initialized
            if grep -q "governance-ai" .gitmodules 2>/dev/null; then
                git submodule update --init "$SUBMODULE_PATH"
            else
                git submodule add "$SUBMODULE_URL" "$SUBMODULE_PATH"
            fi
            
            # Checkout latest tag
            (cd "$SUBMODULE_PATH" && git fetch --tags && git checkout $(git describe --tags $(git rev-list --tags --max-count=1) 2>/dev/null || echo "main"))
            log OK "Initialized submodule"
        fi
    fi
    
    # Verify submodule is usable
    if [[ ! -d "$SUBMODULE_PATH/core/templates/golden-image" ]]; then
        log ERROR "Submodule structure invalid. Expected: $SUBMODULE_PATH/core/templates/golden-image"
        exit 1
    fi
    
    GOVERNANCE_PATH="$REPO_ROOT/$SUBMODULE_PATH"
    GOLDEN_IMAGE="$GOVERNANCE_PATH/core/templates/golden-image"
    GLOBAL_INFERENCE="$GOVERNANCE_PATH/core/inference-rules"
    
    log OK "Submodule ready"
}

#═══════════════════════════════════════════════════════════════════════════════
# PHASE 2: Structure Comparison
#═══════════════════════════════════════════════════════════════════════════════
compare_structure() {
    log STEP "Phase 2: Structure Comparison"
    
    mkdir -p "$REPO_ROOT/.ai/_scratch"
    local REPORT="$REPO_ROOT/.ai/_scratch/alignment-report-$SESSION_ID.md"
    
    cat > "$REPORT" << EOF
# Alignment Report

**Session**: $SESSION_ID
**Generated**: $(date -Iseconds)

## Structure Comparison

| Component | Golden Image | This Repo | Status |
|-----------|--------------|-----------|--------|
EOF

    local missing_count=0
    local ok_count=0
    
    # Check each required component
    declare -A REQUIRED_FILES=(
        [".governance/manifest.json"]="Governance manifest"
        [".governance-local/overrides.yaml"]="Local overrides"
        ["CLAUDE.md"]="AI operating constraints"
        [".ai/ledger/LEDGER.md"]="Operations ledger"
        [".ai/ledger/PLANNING.md"]="Planning log"
        [".ai/_scratch/.gitignore"]="Scratch gitignore"
        ["docs/_shared/router.md"]="Intent router"
    )
    
    for file in "${!REQUIRED_FILES[@]}"; do
        local desc="${REQUIRED_FILES[$file]}"
        local golden_exists="✓"
        local repo_exists="✗"
        local status="MISSING"
        
        [[ -f "$GOLDEN_IMAGE/$file" ]] && golden_exists="✓"
        
        if [[ -f "$REPO_ROOT/$file" ]]; then
            repo_exists="✓"
            status="OK"
            ((ok_count++))
        else
            ((missing_count++))
        fi
        
        echo "| $file | $golden_exists | $repo_exists | $status |" >> "$REPORT"
    done
    
    cat >> "$REPORT" << EOF

## Summary

- **OK**: $ok_count files
- **Missing**: $missing_count files

EOF

    log INFO "Report: $REPORT"
    log INFO "OK: $ok_count, Missing: $missing_count"
    
    MISSING_COUNT=$missing_count
}

#═══════════════════════════════════════════════════════════════════════════════
# PHASE 3: Create Missing Files
#═══════════════════════════════════════════════════════════════════════════════
create_missing_files() {
    log STEP "Phase 3: Create Missing Files"
    
    local created=0
    
    # Create directories
    mkdir -p "$REPO_ROOT/.governance"
    mkdir -p "$REPO_ROOT/.governance-local"
    mkdir -p "$REPO_ROOT/.ai/ledger"
    mkdir -p "$REPO_ROOT/.ai/_scratch"
    mkdir -p "$REPO_ROOT/.ai/inference"
    mkdir -p "$REPO_ROOT/docs/_shared"
    
    # manifest.json
    if [[ ! -f "$REPO_ROOT/.governance/manifest.json" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            log INFO "Would create: .governance/manifest.json"
        else
            cp "$GOLDEN_IMAGE/.governance/manifest.json" "$REPO_ROOT/.governance/"
            log OK "Created: .governance/manifest.json"
            ((created++))
        fi
    fi
    
    # overrides.yaml
    if [[ ! -f "$REPO_ROOT/.governance-local/overrides.yaml" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            log INFO "Would create: .governance-local/overrides.yaml"
        else
            cp "$GOLDEN_IMAGE/.governance-local/overrides.yaml" "$REPO_ROOT/.governance-local/"
            log OK "Created: .governance-local/overrides.yaml"
            ((created++))
        fi
    fi
    
    # CLAUDE.md (only if doesn't exist - don't overwrite)
    if [[ ! -f "$REPO_ROOT/CLAUDE.md" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            log INFO "Would create: CLAUDE.md"
        else
            cp "$GOLDEN_IMAGE/CLAUDE.md" "$REPO_ROOT/"
            log OK "Created: CLAUDE.md"
            ((created++))
        fi
    fi
    
    # Ledger files
    for ledger in LEDGER.md PLANNING.md EFFICIENCY.md; do
        if [[ ! -f "$REPO_ROOT/.ai/ledger/$ledger" ]] && [[ -f "$GOLDEN_IMAGE/.ai/ledger/$ledger" ]]; then
            if [[ "$DRY_RUN" == true ]]; then
                log INFO "Would create: .ai/ledger/$ledger"
            else
                cp "$GOLDEN_IMAGE/.ai/ledger/$ledger" "$REPO_ROOT/.ai/ledger/"
                log OK "Created: .ai/ledger/$ledger"
                ((created++))
            fi
        fi
    done
    
    # Scratch gitignore
    if [[ ! -f "$REPO_ROOT/.ai/_scratch/.gitignore" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            log INFO "Would create: .ai/_scratch/.gitignore"
        else
            echo -e "# Ephemeral files - never commit\n*\n!.gitignore" > "$REPO_ROOT/.ai/_scratch/.gitignore"
            log OK "Created: .ai/_scratch/.gitignore"
            ((created++))
        fi
    fi
    
    # Router.md (only if doesn't exist)
    if [[ ! -f "$REPO_ROOT/docs/_shared/router.md" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            log INFO "Would create: docs/_shared/router.md (template)"
        else
            cp "$GOLDEN_IMAGE/docs/_shared/router.md" "$REPO_ROOT/docs/_shared/"
            log WARN "Created: docs/_shared/router.md - CUSTOMIZE THIS FOR YOUR REPO"
            ((created++))
        fi
    fi
    
    log INFO "Created $created files"
    CREATED_COUNT=$created
}

#═══════════════════════════════════════════════════════════════════════════════
# PHASE 4: Inference Deduplication
#═══════════════════════════════════════════════════════════════════════════════
deduplicate_inference() {
    log STEP "Phase 4: Inference Deduplication"
    
    local LOCAL_INFERENCE="$REPO_ROOT/.ai/inference"
    local duplicates=0
    local kept=0
    
    # Skip if no local inference
    if [[ ! -d "$LOCAL_INFERENCE" ]] || [[ -z "$(ls -A "$LOCAL_INFERENCE" 2>/dev/null)" ]]; then
        log INFO "No local inference rules to deduplicate"
        return 0
    fi
    
    # Compare each local inference file against global
    for local_file in "$LOCAL_INFERENCE"/*.md; do
        [[ ! -f "$local_file" ]] && continue
        local filename=$(basename "$local_file")
        
        # Check if global version exists
        local global_file="$GLOBAL_INFERENCE/$filename"
        
        if [[ -f "$global_file" ]]; then
            # Compare content (ignoring whitespace)
            local local_hash=$(cat "$local_file" | tr -d '[:space:]' | md5sum | cut -d' ' -f1)
            local global_hash=$(cat "$global_file" | tr -d '[:space:]' | md5sum | cut -d' ' -f1)
            
            if [[ "$local_hash" == "$global_hash" ]]; then
                # Exact duplicate
                if [[ "$DRY_RUN" == true ]]; then
                    log INFO "Would remove duplicate: $filename"
                else
                    rm "$local_file"
                    log OK "Removed duplicate: $filename (use global)"
                fi
                ((duplicates++))
            else
                # Similar name but different content - might be repo-specific extension
                log WARN "Local differs from global: $filename - review manually"
                ((kept++))
            fi
        else
            # No global equivalent - this is repo-specific
            log INFO "Repo-specific: $filename (keeping)"
            ((kept++))
        fi
    done
    
    # Create README pointing to global inference
    if [[ "$DRY_RUN" == false ]]; then
        cat > "$LOCAL_INFERENCE/README.md" << EOF
# Local Inference Rules

This directory contains **repo-specific** inference rules only.

## Global Rules

Global inference rules are in the governance submodule:
\`.governance/ai/core/inference-rules/\`

| Global Rule | Description |
|-------------|-------------|
$(ls "$GLOBAL_INFERENCE"/*.md 2>/dev/null | while read f; do echo "| $(basename "$f") | See submodule |"; done)

## Local Rules (Repo-Specific)

$(ls "$LOCAL_INFERENCE"/*.md 2>/dev/null | grep -v README.md | while read f; do echo "- $(basename "$f")"; done || echo "None")

---
*Auto-generated by align-repo.sh*
EOF
    fi
    
    log INFO "Duplicates removed: $duplicates, Repo-specific kept: $kept"
    DUPLICATES_REMOVED=$duplicates
}

#═══════════════════════════════════════════════════════════════════════════════
# PHASE 5: Update .gitignore
#═══════════════════════════════════════════════════════════════════════════════
update_gitignore() {
    log STEP "Phase 5: Update .gitignore"
    
    local gitignore="$REPO_ROOT/.gitignore"
    local additions=0
    
    # Required ignores
    declare -a REQUIRED_IGNORES=(
        ".ai/_scratch/"
        ".governance-local/secrets/"
        "*.plan"
        "*.tfstate"
        "*.tfstate.*"
    )
    
    for pattern in "${REQUIRED_IGNORES[@]}"; do
        if ! grep -qF "$pattern" "$gitignore" 2>/dev/null; then
            if [[ "$DRY_RUN" == true ]]; then
                log INFO "Would add to .gitignore: $pattern"
            else
                echo "$pattern" >> "$gitignore"
                ((additions++))
            fi
        fi
    done
    
    if [[ $additions -gt 0 ]]; then
        log OK "Added $additions patterns to .gitignore"
    else
        log INFO ".gitignore already complete"
    fi
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
    echo "Session:     $SESSION_ID"
    echo "Duration:    ${duration}s"
    echo "Files added: ${CREATED_COUNT:-0}"
    echo "Duplicates:  ${DUPLICATES_REMOVED:-0} removed"
    echo ""
    echo "Reports:"
    echo "  - .ai/_scratch/alignment-report-$SESSION_ID.md"
    echo ""
    echo "Next steps:"
    echo "  1. Review CLAUDE.md and customize for your repo"
    echo "  2. Update docs/_shared/router.md with your directory structure"
    echo "  3. Add repo-specific inference rules to .ai/inference/"
    echo "  4. Commit: git add . && git commit -m 'feat: Align to governance'"
    echo ""
    
    # Log to planning
    if [[ -f "$REPO_ROOT/.ai/ledger/PLANNING.md" ]]; then
        cat >> "$REPO_ROOT/.ai/ledger/PLANNING.md" << EOF

---
### $(date -Iseconds) - Repository Alignment
**Session**: \`$SESSION_ID\` | **Duration**: ${duration}s

| Metric | Value |
|--------|-------|
| Files created | ${CREATED_COUNT:-0} |
| Duplicates removed | ${DUPLICATES_REMOVED:-0} |
| Report | .ai/_scratch/alignment-report-$SESSION_ID.md |
EOF
    fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-update) SKIP_UPDATE=true; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        --interactive) INTERACTIVE=true; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown: $1"; usage ;;
    esac
done

# Header
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       Repository Alignment to Governance Golden Image        ║${NC}"
echo -e "${BLUE}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BLUE}║  Session: $SESSION_ID                              ║${NC}"
echo -e "${BLUE}║  Mode:    $(if $DRY_RUN; then echo "DRY RUN"; else echo "LIVE"; fi)                                            ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Execute phases
setup_submodule
compare_structure
create_missing_files
deduplicate_inference
update_gitignore
print_summary
