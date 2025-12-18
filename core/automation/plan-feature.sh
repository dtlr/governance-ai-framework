#!/usr/bin/env bash
set -euo pipefail

# plan-feature.sh - Transform user request into executable implementation plan
#
# Tracks all created files in MANIFEST.md for cleanup after deployment

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

DRY_RUN=false
INTERACTIVE=false
CLEANUP=false
REQUEST=""
SESSION_ID=$(date +%Y%m%d-%H%M%S)
START_TIME=$(date +%s)

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Transform a user request into an executable implementation plan.

Options:
    --request "text"    The feature/change request
    --dry-run           Show prompts without executing
    --interactive       Run prompts interactively
    --cleanup <dir>     Clean up ephemeral files after deployment
    -h, --help          Show this help message

File Tracking:
    All created files are logged to MANIFEST.md in the feature directory.
    After successful deployment, run --cleanup to remove ephemeral files.

Examples:
    # Plan a feature
    $(basename "$0") --request "Add Redis caching"
    
    # After deployment succeeds, clean up
    $(basename "$0") --cleanup .ai/_scratch/feature-redis-cache
EOF
    exit 0
}

# Initialize manifest
init_manifest() {
    local feature_dir="$1"
    local manifest="$feature_dir/MANIFEST.md"
    
    cat > "$manifest" << EOF
# File Manifest

**Session**: $SESSION_ID
**Created**: $(date -Iseconds)

## File Categories

| Category | Keep After Deploy | Description |
|----------|-------------------|-------------|
| DOCS | ✅ Yes | Documentation (FEATURE.md, PDR.md) |
| RESEARCH | ❌ No | Research artifacts |
| PROMPTS | ❌ No | Execution prompts |
| LOGS | ❌ No | Execution logs |
| TEMP | ❌ No | Temporary working files |

## Files Created

| File | Category | Size | Keep |
|------|----------|------|------|
EOF
}

# Track file creation
track_file() {
    local feature_dir="$1"
    local file_path="$2"
    local category="$3"
    local manifest="$feature_dir/MANIFEST.md"
    
    local keep="❌"
    if [[ "$category" == "DOCS" ]]; then
        keep="✅"
    fi
    
    local size="0"
    if [[ -f "$file_path" ]]; then
        size=$(wc -c < "$file_path" | tr -d ' ')
    fi
    
    echo "| \`$file_path\` | $category | ${size}B | $keep |" >> "$manifest"
}

# Cleanup ephemeral files
cleanup_feature() {
    local feature_dir="$1"
    local manifest="$feature_dir/MANIFEST.md"
    
    if [[ ! -f "$manifest" ]]; then
        echo -e "${RED}Error: No MANIFEST.md found in $feature_dir${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}Cleaning up ephemeral files in $feature_dir${NC}"
    echo ""
    
    local kept=0
    local deleted=0
    
    # Parse manifest and delete non-DOCS files
    while IFS='|' read -r _ file category _ keep _; do
        file=$(echo "$file" | tr -d ' \`')
        category=$(echo "$category" | tr -d ' ')
        keep=$(echo "$keep" | tr -d ' ')
        
        if [[ -z "$file" ]] || [[ "$file" == "File" ]]; then
            continue
        fi
        
        if [[ "$keep" == "❌" ]]; then
            if [[ -f "$file" ]]; then
                rm -f "$file"
                echo -e "  ${RED}✗ Deleted:${NC} $file"
                ((++deleted))
            fi
        else
            echo -e "  ${GREEN}✓ Kept:${NC} $file"
            ((++kept))
        fi
    done < "$manifest"
    
    # Remove empty directories
    find "$feature_dir" -type d -empty -delete 2>/dev/null || true
    
    # Update manifest with cleanup record
    cat >> "$manifest" << EOF

## Cleanup Record

**Cleaned**: $(date -Iseconds)
**Files kept**: $kept
**Files deleted**: $deleted
EOF
    
    echo ""
    echo -e "${GREEN}Cleanup complete: $kept kept, $deleted deleted${NC}"
}

# Ledger function
log_to_ledger() {
    local status="$1"
    local details="$2"
    local ledger_file="$REPO_ROOT/.ai/ledger/LEDGER.md"
    
    mkdir -p "$(dirname "$ledger_file")"
    
    if [[ ! -f "$ledger_file" ]]; then
        cat > "$ledger_file" << 'LEDGER'
# Operations Ledger

Track AI operations for audit and learning.

## Log

LEDGER
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))
    local timestamp=$(date -Iseconds)
    
    cat >> "$ledger_file" << ENTRY

---

### $timestamp - Feature Planning ($status)

**Session**: $SESSION_ID
**Duration**: ${duration}s
**Request**: $(head -1 "$REPO_ROOT/.ai/_scratch/user-request.md" 2>/dev/null | cut -c1-80)...

$details

ENTRY
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --request) REQUEST="$2"; shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        --interactive) INTERACTIVE=true; shift ;;
        --cleanup) CLEANUP=true; cleanup_feature "$2"; exit 0 ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

# Find governance submodule
GOVERNANCE_PATH=""
if [[ -d "$REPO_ROOT/.governance/ai" ]]; then
    GOVERNANCE_PATH="$REPO_ROOT/.governance/ai"
elif [[ -d "$SCRIPT_DIR/../.." ]] && [[ -f "$SCRIPT_DIR/../../00_INDEX/README.md" ]]; then
    GOVERNANCE_PATH="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi

if [[ -z "$GOVERNANCE_PATH" ]]; then
    echo -e "${RED}Error: Could not find governance submodule${NC}"
    exit 1
fi

BUNDLE_PATH="$GOVERNANCE_PATH/core/templates/golden-image/.ai/bundles/feature-planning-v1"

if [[ ! -d "$BUNDLE_PATH" ]]; then
    echo -e "${RED}Error: feature-planning-v1 bundle not found${NC}"
    exit 1
fi

# Create scratch directory
mkdir -p "$REPO_ROOT/.ai/_scratch"
mkdir -p "$REPO_ROOT/.ai/ledger"

# Handle request input
if [[ -n "$REQUEST" ]]; then
    echo "$REQUEST" > "$REPO_ROOT/.ai/_scratch/user-request.md"
elif [[ ! -f "$REPO_ROOT/.ai/_scratch/user-request.md" ]]; then
    echo -e "${YELLOW}Enter your request (Ctrl+D when done):${NC}"
    cat > "$REPO_ROOT/.ai/_scratch/user-request.md"
fi

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           Feature Planning Pipeline                          ║${NC}"
echo -e "${BLUE}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BLUE}║  Session: $SESSION_ID                              ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

if $DRY_RUN; then
    echo -e "${YELLOW}DRY RUN mode${NC}"
    exit 0
fi

# Check for claude CLI
if ! command -v claude &> /dev/null; then
    echo -e "${RED}Error: claude CLI not found${NC}"
    exit 1
fi

# Create feature directory (will be renamed after we know the feature name)
TEMP_FEATURE_DIR="$REPO_ROOT/.ai/_scratch/feature-$SESSION_ID"
mkdir -p "$TEMP_FEATURE_DIR/research"
mkdir -p "$TEMP_FEATURE_DIR/prompts"

# Initialize manifest
init_manifest "$TEMP_FEATURE_DIR"

# Track initial files
track_file "$TEMP_FEATURE_DIR" "$REPO_ROOT/.ai/_scratch/user-request.md" "TEMP"

# Execute prompts
PROMPTS=($(find "$BUNDLE_PATH/prompts" -name "*.md" | sort))
TOTAL=${#PROMPTS[@]}
CURRENT=0
STAGES_COMPLETED=0

for prompt in "${PROMPTS[@]}"; do
    ((++CURRENT))
    PROMPT_NAME=$(basename "$prompt" .md)
    
    echo -e "${BLUE}[$CURRENT/$TOTAL] ${PROMPT_NAME}${NC}"
    
    cd "$REPO_ROOT"
    LOG_FILE="$TEMP_FEATURE_DIR/${PROMPT_NAME}.log"
    
    if claude -p "$(cat "$prompt")" --allowedTools Edit,Write,Bash 2>&1 | tee "$LOG_FILE"; then
        ((++STAGES_COMPLETED))
        track_file "$TEMP_FEATURE_DIR" "$LOG_FILE" "LOGS"
        echo -e "${GREEN}✓ ${PROMPT_NAME}${NC}"
        
        # Track generated files based on stage
        case "$PROMPT_NAME" in
            *research_codebase*)
                track_file "$TEMP_FEATURE_DIR" "$TEMP_FEATURE_DIR/research/codebase.md" "RESEARCH"
                ;;
            *research_docs*)
                track_file "$TEMP_FEATURE_DIR" "$TEMP_FEATURE_DIR/research/docs.md" "RESEARCH"
                ;;
            *validate*)
                track_file "$TEMP_FEATURE_DIR" "$TEMP_FEATURE_DIR/validation.md" "RESEARCH"
                ;;
            *generate_feature*)
                track_file "$TEMP_FEATURE_DIR" "$TEMP_FEATURE_DIR/FEATURE.md" "DOCS"
                ;;
            *generate_pdr*)
                track_file "$TEMP_FEATURE_DIR" "$TEMP_FEATURE_DIR/PDR.md" "DOCS"
                ;;
            *decompose*)
                track_file "$TEMP_FEATURE_DIR" "$TEMP_FEATURE_DIR/tasks.json" "DOCS"
                ;;
            *generate_prompts*)
                for pfile in "$TEMP_FEATURE_DIR/prompts/"*.md; do
                    track_file "$TEMP_FEATURE_DIR" "$pfile" "PROMPTS"
                done
                track_file "$TEMP_FEATURE_DIR" "$TEMP_FEATURE_DIR/execute.sh" "PROMPTS"
                ;;
        esac
    else
        echo -e "${RED}✗ ${PROMPT_NAME} failed${NC}"
        log_to_ledger "FAILED" "Failed at: $PROMPT_NAME"
        exit 1
    fi
    echo ""
done

# Finalize manifest
cat >> "$TEMP_FEATURE_DIR/MANIFEST.md" << EOF

## Summary

**Total files**: $(grep -c "^\|" "$TEMP_FEATURE_DIR/MANIFEST.md" || echo "?")
**Keep after deploy**: $(grep -c "✅" "$TEMP_FEATURE_DIR/MANIFEST.md" || echo "0")
**Delete after deploy**: $(grep -c "❌" "$TEMP_FEATURE_DIR/MANIFEST.md" || echo "0")

## Cleanup Command

After successful deployment:
\`\`\`bash
.governance/ai/core/automation/plan-feature.sh --cleanup $TEMP_FEATURE_DIR
\`\`\`
EOF

# Log success
log_to_ledger "COMPLETED" "**Feature planned**

Stages: $STAGES_COMPLETED/$TOTAL
Directory: $TEMP_FEATURE_DIR

See MANIFEST.md for file tracking."

echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           FEATURE PLANNING COMPLETE                          ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Artifacts: $TEMP_FEATURE_DIR/"
echo "Manifest:  $TEMP_FEATURE_DIR/MANIFEST.md"
echo ""
echo "After deployment succeeds, clean up with:"
echo "  $(basename "$0") --cleanup $TEMP_FEATURE_DIR"
