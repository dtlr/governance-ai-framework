#!/usr/bin/env bash
set -euo pipefail

# align-repo.sh - Align any repository to governance golden-image
# 
# Usage:
#   ./align-repo.sh [--dry-run] [--interactive]
#
# Prerequisites:
#   - Governance submodule at .governance/ai
#   - Claude Code CLI available
#
# This script can be copied to any repo or run from the governance submodule.

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

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Align a repository to the governance golden-image structure.

Options:
    --dry-run       Show what would be done without executing
    --interactive   Run prompts interactively (default: headless)
    -h, --help      Show this help message

Prerequisites:
    - Git repository with governance submodule at .governance/ai
    - Claude Code CLI (claude) available in PATH

Example:
    # From any repo with governance submodule
    .governance/ai/core/automation/align-repo.sh
    
    # Or copy this script and run
    ./align-repo.sh --dry-run
EOF
    exit 0
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
    echo "Expected at: $REPO_ROOT/.governance/ai"
    echo ""
    echo "Initialize with:"
    echo "  git submodule add https://github.com/dtlr/governance-ai-framework .governance/ai"
    exit 1
fi

BUNDLE_PATH="$GOVERNANCE_PATH/core/templates/golden-image/.ai/bundles/repo-alignment-v1"

if [[ ! -d "$BUNDLE_PATH" ]]; then
    echo -e "${RED}Error: repo-alignment-v1 bundle not found${NC}"
    echo "Expected at: $BUNDLE_PATH"
    echo ""
    echo "Update governance submodule:"
    echo "  cd .governance/ai && git pull origin main"
    exit 1
fi

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       Repository Alignment to Governance Golden Image        ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Repository:  ${GREEN}$REPO_ROOT${NC}"
echo -e "Governance:  ${GREEN}$GOVERNANCE_PATH${NC}"
echo -e "Bundle:      ${GREEN}$BUNDLE_PATH${NC}"
echo -e "Mode:        ${YELLOW}$(if $DRY_RUN; then echo "DRY RUN"; elif $INTERACTIVE; then echo "INTERACTIVE"; else echo "HEADLESS"; fi)${NC}"
echo ""

# Create scratch directory
mkdir -p "$REPO_ROOT/.ai/_scratch"

# List prompts
PROMPTS=($(find "$BUNDLE_PATH/prompts" -name "*.md" | sort))

echo -e "${BLUE}Prompts to execute:${NC}"
for prompt in "${PROMPTS[@]}"; do
    echo "  - $(basename "$prompt")"
done
echo ""

if $DRY_RUN; then
    echo -e "${YELLOW}DRY RUN: No changes will be made${NC}"
    echo ""
    echo "Would execute:"
    for prompt in "${PROMPTS[@]}"; do
        echo "  claude -p \"\$(cat $prompt)\" --allowedTools Edit,Write,Bash"
    done
    exit 0
fi

# Check for claude CLI
if ! command -v claude &> /dev/null; then
    echo -e "${RED}Error: claude CLI not found${NC}"
    echo "Install Claude Code CLI first."
    exit 1
fi

# Execute prompts
TOTAL=${#PROMPTS[@]}
CURRENT=0

for prompt in "${PROMPTS[@]}"; do
    ((++CURRENT))
    PROMPT_NAME=$(basename "$prompt" .md)
    
    echo -e "${BLUE}[$CURRENT/$TOTAL] Executing: $PROMPT_NAME${NC}"
    
    if $INTERACTIVE; then
        echo -e "${YELLOW}Paste the following prompt into Claude:${NC}"
        echo "---"
        cat "$prompt"
        echo "---"
        read -p "Press Enter when complete..."
    else
        # Headless execution
        cd "$REPO_ROOT"
        claude -p "$(cat "$prompt")" --allowedTools Edit,Write,Bash 2>&1 | tee ".ai/_scratch/${PROMPT_NAME}.log"
    fi
    
    echo -e "${GREEN}✓ $PROMPT_NAME complete${NC}"
    echo ""
done

echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    ALIGNMENT COMPLETE                        ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Outputs:"
echo "  - .ai/_scratch/repo-shape.md"
echo "  - .ai/_scratch/golden-comparison.md"
echo "  - .ai/_scratch/alignment-plan.md"
echo "  - .ai/_scratch/alignment-verification.md"
echo ""
echo "Review generated files and customize for your project."
