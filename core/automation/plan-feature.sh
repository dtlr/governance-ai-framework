#!/usr/bin/env bash
set -euo pipefail

# plan-feature.sh - Transform user request into executable implementation plan
#
# Usage:
#   ./plan-feature.sh [--request "description"] [--dry-run] [--interactive]
#
# Integrates with:
#   - .ai/ledger/LEDGER.md (operations audit)
#   - .ai/ledger/EFFICIENCY.md (cost tracking)

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
SESSION_ID=$(date +%Y%m%d-%H%M%S)
START_TIME=$(date +%s)

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Transform a user request into an executable implementation plan.

Options:
    --request "text"    The feature/change request (or use stdin)
    --dry-run           Show prompts without executing
    --interactive       Run prompts interactively
    -h, --help          Show this help message

Outputs to:
    .ai/_scratch/feature-<name>/   Generated artifacts
    .ai/ledger/LEDGER.md           Operations audit entry
    .ai/ledger/EFFICIENCY.md       Cost tracking (if exists)

Examples:
    $(basename "$0") --request "Add Redis caching"
    $(basename "$0") --interactive
EOF
    exit 0
}

# Ledger functions
log_to_ledger() {
    local status="$1"
    local details="$2"
    local ledger_file="$REPO_ROOT/.ai/ledger/LEDGER.md"
    
    # Create ledger if it doesn't exist
    if [[ ! -f "$ledger_file" ]]; then
        mkdir -p "$(dirname "$ledger_file")"
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

### $timestamp - Feature Planning ($status)

**Session**: $SESSION_ID
**Duration**: ${duration}s
**Request**: $(head -1 "$REPO_ROOT/.ai/_scratch/user-request.md" 2>/dev/null | cut -c1-80)...

$details

ENTRY
    
    echo -e "${GREEN}Logged to LEDGER.md${NC}"
}

log_efficiency() {
    local operation_type="$1"
    local status="$2"
    local efficiency_file="$REPO_ROOT/.ai/ledger/EFFICIENCY.md"
    
    # Only log if efficiency file exists
    if [[ ! -f "$efficiency_file" ]]; then
        return 0
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))
    local timestamp=$(date +%Y-%m-%d)
    
    # Append to rolling log section (simplified - full tracking would need more)
    echo "" >> "$efficiency_file"
    echo "| $timestamp | feature-planning | $operation_type | ${duration}s | $status |" >> "$efficiency_file"
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
mkdir -p "$REPO_ROOT/.ai/ledger"

# Handle request input
if [[ -n "$REQUEST" ]]; then
    echo "$REQUEST" > "$REPO_ROOT/.ai/_scratch/user-request.md"
elif [[ ! -f "$REPO_ROOT/.ai/_scratch/user-request.md" ]]; then
    echo -e "${YELLOW}No request provided. Enter your request (Ctrl+D when done):${NC}"
    cat > "$REPO_ROOT/.ai/_scratch/user-request.md"
fi

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           Feature Planning Pipeline                          ║${NC}"
echo -e "${BLUE}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BLUE}║  Session: $SESSION_ID                              ║${NC}"
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
    log_to_ledger "DRY_RUN" "Dry run only - no execution"
    exit 0
fi

# Check for claude CLI
if ! command -v claude &> /dev/null; then
    echo -e "${RED}Error: claude CLI not found${NC}"
    log_to_ledger "ERROR" "Claude CLI not found"
    exit 1
fi

# Track stage results
STAGES_COMPLETED=0
STAGES_FAILED=0
BLOCKED=false
WARNINGS=""

# Execute prompts
TOTAL=${#PROMPTS[@]}
CURRENT=0

for prompt in "${PROMPTS[@]}"; do
    ((++CURRENT))
    PROMPT_NAME=$(basename "$prompt" .md)
    
    echo -e "${BLUE}[$CURRENT/$TOTAL] ${PROMPT_NAME}${NC}"
    
    if $INTERACTIVE; then
        echo -e "${YELLOW}Press Enter to execute or 's' to skip:${NC}"
        read -t 10 -n 1 response || response=""
        if [[ "$response" == "s" ]]; then
            echo "Skipped"
            continue
        fi
    fi
    
    cd "$REPO_ROOT"
    
    # Execute with logging
    LOG_FILE=".ai/_scratch/${PROMPT_NAME}.log"
    if claude -p "$(cat "$prompt")" --allowedTools Edit,Write,Bash 2>&1 | tee "$LOG_FILE"; then
        echo -e "${GREEN}✓ ${PROMPT_NAME} complete${NC}"
        ((++STAGES_COMPLETED))
        
        # Check for validation blocking
        if [[ "$PROMPT_NAME" == *"validate"* ]]; then
            if grep -q "BLOCKED" ".ai/_scratch/validation.md" 2>/dev/null; then
                BLOCKED=true
                echo -e "${RED}⛔ Validation BLOCKED further progress${NC}"
                log_to_ledger "BLOCKED" "**Blocked at validation stage**

Stages completed: $STAGES_COMPLETED/$TOTAL

See: .ai/_scratch/validation.md for details"
                exit 1
            fi
            
            # Capture warnings
            if grep -q "WARNING" ".ai/_scratch/validation.md" 2>/dev/null; then
                WARNINGS=$(grep -A2 "WARNING" ".ai/_scratch/validation.md" | head -10)
            fi
        fi
    else
        echo -e "${RED}✗ ${PROMPT_NAME} failed${NC}"
        ((++STAGES_FAILED))
        
        log_to_ledger "FAILED" "**Failed at stage: $PROMPT_NAME**

Stages completed: $STAGES_COMPLETED
Stages failed: $STAGES_FAILED

Check: .ai/_scratch/${PROMPT_NAME}.log"
        exit 1
    fi
    echo ""
done

# Find generated feature directory
FEATURE_DIR=$(ls -td "$REPO_ROOT/.ai/_scratch/feature-"* 2>/dev/null | head -1)
FEATURE_NAME=$(basename "$FEATURE_DIR" 2>/dev/null || echo "unknown")

# Count generated tasks
TASK_COUNT=0
if [[ -f "$FEATURE_DIR/tasks.json" ]]; then
    TASK_COUNT=$(grep -c '"id"' "$FEATURE_DIR/tasks.json" 2>/dev/null || echo "0")
fi

# Log success to ledger
log_to_ledger "COMPLETED" "**Feature: $FEATURE_NAME**

Stages: $STAGES_COMPLETED/$TOTAL completed
Tasks generated: $TASK_COUNT
$(if [[ -n "$WARNINGS" ]]; then echo "
**Warnings:**
$WARNINGS"; fi)

**Artifacts:**
- FEATURE.md: $(test -f "$FEATURE_DIR/FEATURE.md" && echo "✓" || echo "✗")
- PDR.md: $(test -f "$FEATURE_DIR/PDR.md" && echo "✓" || echo "✗")  
- tasks.json: $(test -f "$FEATURE_DIR/tasks.json" && echo "✓" || echo "✗")
- prompts/: $(ls "$FEATURE_DIR/prompts/"*.md 2>/dev/null | wc -l) files

**Next:** Review artifacts, then run:
\`\`\`bash
$FEATURE_DIR/execute.sh
\`\`\`"

# Log to efficiency tracker
log_efficiency "plan" "complete"

echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           FEATURE PLANNING COMPLETE                          ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Session:  ${CYAN}$SESSION_ID${NC}"
echo -e "Feature:  ${CYAN}$FEATURE_NAME${NC}"
echo -e "Stages:   ${GREEN}$STAGES_COMPLETED${NC}/$TOTAL completed"
echo -e "Tasks:    ${CYAN}$TASK_COUNT${NC} generated"
if [[ -n "$WARNINGS" ]]; then
    echo -e "Warnings: ${YELLOW}Yes - review validation.md${NC}"
fi
echo ""
echo "Artifacts: $FEATURE_DIR/"
echo ""
echo "Next steps:"
echo "  1. Review FEATURE.md and PDR.md"
echo "  2. Check validation.md for warnings"
echo "  3. Execute: $FEATURE_DIR/execute.sh"
echo ""
echo -e "${GREEN}Logged to .ai/ledger/LEDGER.md${NC}"
