#!/usr/bin/env bash
set -euo pipefail

# plan-feature.sh - Transform user request into executable implementation plan
#
# Usage:
#   ./plan-feature.sh [--request "description"] [--dry-run] [--interactive]
#
# This script runs the feature-planning-v1 bundle to:
# 1. Understand the user's request
# 2. Research codebase and documentation
# 3. Validate approach and push back on bad ideas
# 4. Generate FEATURE.md and PDR.md
# 5. Decompose into atomic tasks
# 6. Generate executable prompts

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
REQUEST=""

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Transform a user request into an executable implementation plan.

Options:
    --request "text"    The feature/change request (or use stdin)
    --dry-run           Show prompts without executing
    --interactive       Run prompts interactively (default: headless)
    -h, --help          Show this help message

Examples:
    # With inline request
    $(basename "$0") --request "Add Redis caching to reduce DB load"
    
    # With request file
    echo "Add Redis caching..." > .ai/_scratch/user-request.md
    $(basename "$0")
    
    # Interactive mode
    $(basename "$0") --interactive
    
    # Dry run to see what would happen
    $(basename "$0") --request "Add feature X" --dry-run

Output:
    .ai/_scratch/feature-<name>/
    ├── FEATURE.md           # User story, acceptance criteria
    ├── PDR.md               # Technical design record
    ├── tasks.json           # Task dependency graph
    ├── execute.sh           # Runner script
    └── prompts/             # Atomic prompt files
EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --request) REQUEST="$2"; shift 2 ;;
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
    exit 1
fi

BUNDLE_PATH="$GOVERNANCE_PATH/core/templates/golden-image/.ai/bundles/feature-planning-v1"

if [[ ! -d "$BUNDLE_PATH" ]]; then
    echo -e "${RED}Error: feature-planning-v1 bundle not found${NC}"
    exit 1
fi

# Create scratch directory
mkdir -p "$REPO_ROOT/.ai/_scratch"

# Handle request input
if [[ -n "$REQUEST" ]]; then
    echo "$REQUEST" > "$REPO_ROOT/.ai/_scratch/user-request.md"
elif [[ ! -f "$REPO_ROOT/.ai/_scratch/user-request.md" ]]; then
    echo -e "${YELLOW}No request provided. Enter your request (Ctrl+D when done):${NC}"
    cat > "$REPO_ROOT/.ai/_scratch/user-request.md"
fi

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           Feature Planning Pipeline                          ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Request:${NC}"
cat "$REPO_ROOT/.ai/_scratch/user-request.md" | head -5
echo ""
echo -e "Mode: ${YELLOW}$(if $DRY_RUN; then echo "DRY RUN"; elif $INTERACTIVE; then echo "INTERACTIVE"; else echo "HEADLESS"; fi)${NC}"
echo ""

# List prompts
PROMPTS=($(find "$BUNDLE_PATH/prompts" -name "*.md" | sort))

echo -e "${BLUE}Pipeline stages:${NC}"
for prompt in "${PROMPTS[@]}"; do
    echo "  → $(basename "$prompt" .md)"
done
echo ""

if $DRY_RUN; then
    echo -e "${YELLOW}DRY RUN: Showing prompts without executing${NC}"
    echo ""
    for prompt in "${PROMPTS[@]}"; do
        echo -e "${CYAN}═══ $(basename "$prompt") ═══${NC}"
        head -20 "$prompt"
        echo "..."
        echo ""
    done
    exit 0
fi

# Check for claude CLI
if ! command -v claude &> /dev/null; then
    echo -e "${RED}Error: claude CLI not found${NC}"
    exit 1
fi

# Execute prompts
TOTAL=${#PROMPTS[@]}
CURRENT=0

for prompt in "${PROMPTS[@]}"; do
    ((++CURRENT))
    PROMPT_NAME=$(basename "$prompt" .md)
    
    echo -e "${BLUE}[$CURRENT/$TOTAL] ${PROMPT_NAME}${NC}"
    
    if $INTERACTIVE; then
        echo -e "${YELLOW}Review and paste prompt, or press Enter to auto-execute:${NC}"
        read -t 5 -p "" || true
    fi
    
    cd "$REPO_ROOT"
    
    # Execute with logging
    LOG_FILE=".ai/_scratch/${PROMPT_NAME}.log"
    if claude -p "$(cat "$prompt")" --allowedTools Edit,Write,Bash 2>&1 | tee "$LOG_FILE"; then
        echo -e "${GREEN}✓ ${PROMPT_NAME} complete${NC}"
    else
        echo -e "${RED}✗ ${PROMPT_NAME} failed - check $LOG_FILE${NC}"
        
        # Check if this is a blocking stage
        if [[ "$PROMPT_NAME" == *"validate"* ]]; then
            echo -e "${RED}Validation failed. Review .ai/_scratch/validation.md${NC}"
            exit 1
        fi
    fi
    echo ""
done

echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           FEATURE PLANNING COMPLETE                          ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Generated artifacts in .ai/_scratch/feature-*/"
echo ""
echo "Next steps:"
echo "  1. Review FEATURE.md and PDR.md"
echo "  2. Check validation.md for any warnings"
echo "  3. Execute: .ai/_scratch/feature-*/execute.sh"
