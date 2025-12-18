#!/usr/bin/env bash
set -euo pipefail

# align-repo.sh - Align any repository to governance golden-image
#
# Integrates with:
#   - .ai/ledger/LEDGER.md (operations audit)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DRY_RUN=false
INTERACTIVE=false
SESSION_ID=$(date +%Y%m%d-%H%M%S)
START_TIME=$(date +%s)

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Align a repository to the governance golden-image structure.

Options:
    --dry-run       Show what would be done without executing
    --interactive   Run prompts interactively
    -h, --help      Show this help message

Outputs to:
    .ai/ledger/LEDGER.md   Operations audit entry

Example:
    .governance/ai/core/automation/align-repo.sh
EOF
    exit 0
}

# Ledger function
log_to_ledger() {
    local status="$1"
    local details="$2"
    local ledger_file="$REPO_ROOT/.ai/ledger/LEDGER.md"
    
    # Create ledger directory if needed
    mkdir -p "$(dirname "$ledger_file")"
    
    # Create ledger if it doesn't exist
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
    
    # Append entry
    cat >> "$ledger_file" << ENTRY

---

### $timestamp - Repository Alignment ($status)

**Session**: $SESSION_ID
**Duration**: ${duration}s

$details

ENTRY
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true; shift ;;
        --interactive) INTERACTIVE=true; shift ;;
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
    echo "Initialize with:"
    echo "  git submodule add https://github.com/dtlr/governance-ai-framework .governance/ai"
    exit 1
fi

BUNDLE_PATH="$GOVERNANCE_PATH/core/templates/golden-image/.ai/bundles/repo-alignment-v1"

if [[ ! -d "$BUNDLE_PATH" ]]; then
    echo -e "${RED}Error: repo-alignment-v1 bundle not found${NC}"
    exit 1
fi

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       Repository Alignment to Governance Golden Image        ║${NC}"
echo -e "${BLUE}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BLUE}║  Session: $SESSION_ID                              ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Repository:  ${GREEN}$REPO_ROOT${NC}"
echo -e "Mode:        ${YELLOW}$(if $DRY_RUN; then echo "DRY RUN"; elif $INTERACTIVE; then echo "INTERACTIVE"; else echo "HEADLESS"; fi)${NC}"
echo ""

# Create scratch directory
mkdir -p "$REPO_ROOT/.ai/_scratch"
mkdir -p "$REPO_ROOT/.ai/ledger"

# List prompts
PROMPTS=($(find "$BUNDLE_PATH/prompts" -name "*.md" | sort))

echo -e "${BLUE}Prompts to execute:${NC}"
for prompt in "${PROMPTS[@]}"; do
    echo "  - $(basename "$prompt")"
done
echo ""

if $DRY_RUN; then
    echo -e "${YELLOW}DRY RUN: No changes will be made${NC}"
    log_to_ledger "DRY_RUN" "Dry run only - no execution"
    exit 0
fi

# Check for claude CLI
if ! command -v claude &> /dev/null; then
    echo -e "${RED}Error: claude CLI not found${NC}"
    log_to_ledger "ERROR" "Claude CLI not found"
    exit 1
fi

# Track progress
STAGES_COMPLETED=0
FILES_CREATED=0

# Execute prompts
TOTAL=${#PROMPTS[@]}
CURRENT=0

for prompt in "${PROMPTS[@]}"; do
    ((++CURRENT))
    PROMPT_NAME=$(basename "$prompt" .md)
    
    echo -e "${BLUE}[$CURRENT/$TOTAL] Executing: $PROMPT_NAME${NC}"
    
    if $INTERACTIVE; then
        read -p "Press Enter to continue..."
    fi
    
    cd "$REPO_ROOT"
    LOG_FILE=".ai/_scratch/${PROMPT_NAME}.log"
    
    if claude -p "$(cat "$prompt")" --allowedTools Edit,Write,Bash 2>&1 | tee "$LOG_FILE"; then
        ((++STAGES_COMPLETED))
        echo -e "${GREEN}✓ $PROMPT_NAME complete${NC}"
    else
        echo -e "${RED}✗ $PROMPT_NAME failed${NC}"
        log_to_ledger "FAILED" "**Failed at: $PROMPT_NAME**

Stages completed: $STAGES_COMPLETED/$TOTAL

Check: .ai/_scratch/${PROMPT_NAME}.log"
        exit 1
    fi
    echo ""
done

# Count created files (rough estimate from scratch logs)
FILES_CREATED=$(grep -l "created\|Created\|wrote\|Wrote" .ai/_scratch/*.log 2>/dev/null | wc -l || echo "?")

# Log success
log_to_ledger "COMPLETED" "**Repository aligned to golden-image**

Stages: $STAGES_COMPLETED/$TOTAL completed

**Outputs:**
- .ai/_scratch/repo-shape.md
- .ai/_scratch/golden-comparison.md
- .ai/_scratch/alignment-plan.md
- .ai/_scratch/alignment-verification.md

**Next:** Review generated governance files and customize for your project."

echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    ALIGNMENT COMPLETE                        ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Session: ${CYAN}$SESSION_ID${NC}"
echo -e "Stages:  ${GREEN}$STAGES_COMPLETED${NC}/$TOTAL"
echo ""
echo "Review generated files and customize for your project."
echo ""
echo -e "${GREEN}Logged to .ai/ledger/LEDGER.md${NC}"
