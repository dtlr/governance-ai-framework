#!/usr/bin/env bash
set -euo pipefail

# plan-feature.sh - Feature planning + standalone research
#
# Modes:
#   --research    Deep research mode (no repo changes)
#   (default)     Feature planning with implementation

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

# Modes
MODE="feature"  # feature, research
DRY_RUN=false
INTERACTIVE=false
DEFER_ISSUE=false
REQUEST=""
EXECUTE_SCOPE="review"
SESSION_ID=$(date +%Y%m%d-%H%M%S)
START_TIME=$(date +%s)

usage() {
    cat << EOF
Usage: $(basename "$0") [MODE] [OPTIONS]

Modes:
    --research          Deep research mode (standalone, no repo changes)
    (default)           Feature planning with implementation

Research Mode Options:
    --question "text"   The research question
    --output FILE       Output file (default: .ai/_scratch/research-SESSION.md)

Feature Mode Options:
    --request "text"    The feature/change request
    --execute SCOPE     Execution scope: all, p0-p1, p0, none, custom:01,02
    --defer-issue       Create GitHub issue for deferred tasks

Common Options:
    --dry-run           Show what would happen
    --interactive       Run interactively
    -h, --help          Show this help

Examples:
    # Deep research (standalone)
    $(basename "$0") --research --question "Best way to manage golden Linux images on Azure"
    
    # Feature planning
    $(basename "$0") --request "Add Redis caching"
    
    # Feature planning, execute critical only
    $(basename "$0") --request "Add Redis" --execute p0-p1 --defer-issue
EOF
    exit 0
}

# Log to PLANNING.md
log_to_planning() {
    local status="$1"
    local details="$2"
    local planning_file="$REPO_ROOT/.ai/ledger/PLANNING.md"
    
    mkdir -p "$(dirname "$planning_file")"
    [[ ! -f "$planning_file" ]] && echo "# Planning Log" > "$planning_file"
    
    local duration=$(($(date +%s) - START_TIME))
    cat >> "$planning_file" << ENTRY

---
### $(date -Iseconds) - $MODE ($status)
**Session**: \`$SESSION_ID\` | **Duration**: ${duration}s
$details
ENTRY
}

# Create GitHub issue
create_defer_issue() {
    local feature_dir="$1"
    local deferred_tasks="$2"
    local feature_name=$(basename "$feature_dir")
    
    local issue_body="## Deferred: $feature_name
**Session**: $SESSION_ID

### Deferred Tasks
$deferred_tasks

### Context
See: \`$feature_dir/\`"
    
    if command -v gh &> /dev/null; then
        local issue_url=$(gh issue create --title "🔮 Deferred: $feature_name" --body "$issue_body" --label "ai-deferred,backlog" 2>/dev/null || echo "")
        [[ -n "$issue_url" ]] && { echo -e "${GREEN}✓ Issue: $issue_url${NC}"; echo "$issue_url" > "$feature_dir/DEFERRED_ISSUE.txt"; return 0; }
    fi
    
    echo "$issue_body" > "$feature_dir/DEFERRED_WORK.md"
    echo -e "${YELLOW}Created: $feature_dir/DEFERRED_WORK.md${NC}"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --research) MODE="research"; shift ;;
        --question) REQUEST="$2"; shift 2 ;;
        --request) REQUEST="$2"; shift 2 ;;
        --output) OUTPUT_FILE="$2"; shift 2 ;;
        --execute) EXECUTE_SCOPE="$2"; shift 2 ;;
        --defer-issue) DEFER_ISSUE=true; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        --interactive) INTERACTIVE=true; shift ;;
        --cleanup) echo "Cleanup: $2"; exit 0 ;;
        -h|--help) usage ;;
        *) echo "Unknown: $1"; usage ;;
    esac
done

# Find governance
GOVERNANCE_PATH=""
[[ -d "$REPO_ROOT/.governance/ai" ]] && GOVERNANCE_PATH="$REPO_ROOT/.governance/ai"

BUNDLE_PATH="${GOVERNANCE_PATH:-$SCRIPT_DIR/..}/core/templates/golden-image/.ai/bundles/feature-planning-v1"

# Setup
mkdir -p "$REPO_ROOT/.ai/_scratch"
mkdir -p "$REPO_ROOT/.ai/ledger"

# Handle input
[[ -n "$REQUEST" ]] && echo "$REQUEST" > "$REPO_ROOT/.ai/_scratch/user-request.md"
[[ ! -f "$REPO_ROOT/.ai/_scratch/user-request.md" ]] && {
    echo -e "${YELLOW}Enter your question/request (Ctrl+D when done):${NC}"
    cat > "$REPO_ROOT/.ai/_scratch/user-request.md"
}

REQUEST_PREVIEW=$(head -1 "$REPO_ROOT/.ai/_scratch/user-request.md" | cut -c1-50)

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
if [[ "$MODE" == "research" ]]; then
echo -e "${BLUE}║           Deep Research Mode                                 ║${NC}"
else
echo -e "${BLUE}║           Feature Planning Pipeline                          ║${NC}"
fi
echo -e "${BLUE}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BLUE}║  Session: $SESSION_ID                              ║${NC}"
echo -e "${BLUE}║  Input:   ${REQUEST_PREVIEW}...${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

[[ "$DRY_RUN" == true ]] && { echo "DRY RUN"; exit 0; }
command -v claude &> /dev/null || { echo -e "${RED}Error: claude CLI not found${NC}"; exit 1; }

#═══════════════════════════════════════════════════════════════════════════════
# RESEARCH MODE
#═══════════════════════════════════════════════════════════════════════════════
if [[ "$MODE" == "research" ]]; then
    OUTPUT_DIR="$REPO_ROOT/.ai/_scratch/research-$SESSION_ID"
    mkdir -p "$OUTPUT_DIR"
    
    echo -e "${MAGENTA}═══ RESEARCH MODE ═══${NC}"
    echo ""
    
    # Step 1: Create research plan
    echo -e "${BLUE}→ Creating research plan...${NC}"
    prompt="$BUNDLE_PATH/prompts/00a_research_question.md"
    if [[ -f "$prompt" ]]; then
        claude -p "$(cat "$prompt")" --allowedTools Edit,Write,Bash 2>&1 | tee "$OUTPUT_DIR/00_plan.log"
    else
        # Inline prompt if file doesn't exist
        claude -p "You are a Cloud Architect. Analyze this question and create a research plan:

$(cat "$REPO_ROOT/.ai/_scratch/user-request.md")

Output a structured research plan to .ai/_scratch/research-plan.md with:
1. Question type (ARCHITECTURE/COMPARISON/BEST_PRACTICE/IMPLEMENTATION)
2. Sources to consult (official docs, community)
3. Sub-questions to answer
4. Expected output format" --allowedTools Edit,Write,Bash 2>&1 | tee "$OUTPUT_DIR/00_plan.log"
    fi
    echo -e "${GREEN}✓ Research plan created${NC}"
    
    # Step 2: Execute deep research
    echo ""
    echo -e "${BLUE}→ Executing deep research...${NC}"
    prompt="$BUNDLE_PATH/prompts/00b_deep_research.md"
    if [[ -f "$prompt" ]]; then
        claude -p "$(cat "$prompt")" --allowedTools Edit,Write,Bash 2>&1 | tee "$OUTPUT_DIR/01_research.log"
    else
        claude -p "Execute the research plan in .ai/_scratch/research-plan.md.

For the question: $(cat "$REPO_ROOT/.ai/_scratch/user-request.md")

Research thoroughly and output to .ai/_scratch/research-findings.md with:
1. Executive Summary
2. TL;DR Recommendation
3. Options comparison (if applicable)
4. Pros/Cons for each option
5. Cost estimates
6. Security considerations
7. Sources consulted
8. Next steps" --allowedTools Edit,Write,Bash 2>&1 | tee "$OUTPUT_DIR/01_research.log"
    fi
    echo -e "${GREEN}✓ Research complete${NC}"
    
    # Move outputs to research directory
    [[ -f "$REPO_ROOT/.ai/_scratch/research-plan.md" ]] && mv "$REPO_ROOT/.ai/_scratch/research-plan.md" "$OUTPUT_DIR/"
    [[ -f "$REPO_ROOT/.ai/_scratch/research-findings.md" ]] && mv "$REPO_ROOT/.ai/_scratch/research-findings.md" "$OUTPUT_DIR/"
    
    # Summary
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           RESEARCH COMPLETE                                  ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Output: $OUTPUT_DIR/"
    echo ""
    
    # Show executive summary if available
    if [[ -f "$OUTPUT_DIR/research-findings.md" ]]; then
        echo -e "${CYAN}═══ Executive Summary ═══${NC}"
        sed -n '/## Executive Summary/,/## /p' "$OUTPUT_DIR/research-findings.md" | head -10
        echo ""
        echo -e "${CYAN}═══ Recommendation ═══${NC}"
        sed -n '/## TL;DR/,/---/p' "$OUTPUT_DIR/research-findings.md" | head -10
    fi
    
    echo ""
    echo "Full report: $OUTPUT_DIR/research-findings.md"
    
    # Ask if user wants to proceed to implementation
    if [[ "$INTERACTIVE" == true ]]; then
        echo ""
        read -p "Create implementation plan from this research? [y/N]: " proceed
        if [[ "$proceed" =~ ^[Yy] ]]; then
            echo -e "${BLUE}Switching to feature planning mode...${NC}"
            # Re-run in feature mode with the research as context
            MODE="feature"
            # Continue below
        else
            log_to_planning "COMPLETED" "Research only. Output: \`$OUTPUT_DIR/\`"
            echo -e "${GREEN}Logged to .ai/ledger/PLANNING.md${NC}"
            exit 0
        fi
    else
        log_to_planning "COMPLETED" "Research only. Output: \`$OUTPUT_DIR/\`"
        echo -e "${GREEN}Logged to .ai/ledger/PLANNING.md${NC}"
        exit 0
    fi
fi

#═══════════════════════════════════════════════════════════════════════════════
# FEATURE PLANNING MODE
#═══════════════════════════════════════════════════════════════════════════════
FEATURE_DIR="$REPO_ROOT/.ai/_scratch/feature-$SESSION_ID"
mkdir -p "$FEATURE_DIR/research" "$FEATURE_DIR/prompts"

echo -e "${MAGENTA}═══ PHASE 1: Research & Planning ═══${NC}"

for num in 00 01 02 03 04 05; do
    prompt=$(find "$BUNDLE_PATH/prompts" -name "${num}_*.md" 2>/dev/null | head -1)
    [[ -z "$prompt" ]] && continue
    [[ "$(basename "$prompt")" == "00a_"* ]] && continue  # Skip research-only prompts
    [[ "$(basename "$prompt")" == "00b_"* ]] && continue
    
    PROMPT_NAME=$(basename "$prompt" .md)
    echo -e "${BLUE}→ $PROMPT_NAME${NC}"
    
    if claude -p "$(cat "$prompt")" --allowedTools Edit,Write,Bash 2>&1 | tee "$FEATURE_DIR/${PROMPT_NAME}.log"; then
        echo -e "${GREEN}✓${NC}"
    else
        log_to_planning "FAILED" "Failed at: $PROMPT_NAME"
        exit 1
    fi
done

echo ""
echo -e "${MAGENTA}═══ PHASE 2: Decomposition ═══${NC}"

for num in 06 06b; do
    prompt=$(find "$BUNDLE_PATH/prompts" -name "${num}*.md" 2>/dev/null | head -1)
    [[ -z "$prompt" ]] && continue
    PROMPT_NAME=$(basename "$prompt" .md)
    echo -e "${BLUE}→ $PROMPT_NAME${NC}"
    claude -p "$(cat "$prompt")" --allowedTools Edit,Write,Bash 2>&1 | tee "$FEATURE_DIR/${PROMPT_NAME}.log"
done

# Show review
echo ""
echo -e "${MAGENTA}═══ TASK REVIEW ═══${NC}"
[[ -f "$FEATURE_DIR/REVIEW.md" ]] && cat "$FEATURE_DIR/REVIEW.md"

# User decision
if [[ "$EXECUTE_SCOPE" == "review" ]]; then
    echo ""
    read -p "Execute scope? [all/p0-p1/p0/none/custom]: " EXECUTE_SCOPE
    EXECUTE_SCOPE=${EXECUTE_SCOPE:-all}
fi

# Determine tasks
TASKS_TO_EXECUTE=""
TASKS_TO_DEFER=""

case "$EXECUTE_SCOPE" in
    all) TASKS_TO_EXECUTE="all" ;;
    p0-p1)
        TASKS_TO_EXECUTE=$(jq -r '.tasks[] | select(.priority == "P0" or .priority == "P1") | .id' "$FEATURE_DIR/tasks.json" 2>/dev/null | tr '\n' ',' | sed 's/,$//')
        TASKS_TO_DEFER=$(jq -r '.tasks[] | select(.priority == "P2" or .priority == "P3") | "- Task \(.id): \(.name) [\(.priority)]"' "$FEATURE_DIR/tasks.json" 2>/dev/null)
        ;;
    p0)
        TASKS_TO_EXECUTE=$(jq -r '.tasks[] | select(.priority == "P0") | .id' "$FEATURE_DIR/tasks.json" 2>/dev/null | tr '\n' ',' | sed 's/,$//')
        TASKS_TO_DEFER=$(jq -r '.tasks[] | select(.priority != "P0") | "- Task \(.id): \(.name) [\(.priority)]"' "$FEATURE_DIR/tasks.json" 2>/dev/null)
        ;;
    none)
        TASKS_TO_DEFER=$(jq -r '.tasks[] | "- Task \(.id): \(.name) [\(.priority)]"' "$FEATURE_DIR/tasks.json" 2>/dev/null)
        ;;
    custom:*)
        TASKS_TO_EXECUTE="${EXECUTE_SCOPE#custom:}"
        ;;
esac

# Handle deferred
if [[ -n "$TASKS_TO_DEFER" ]]; then
    echo ""
    echo -e "${YELLOW}═══ DEFERRED ═══${NC}"
    echo "$TASKS_TO_DEFER"
    [[ "$DEFER_ISSUE" == true ]] && create_defer_issue "$FEATURE_DIR" "$TASKS_TO_DEFER"
fi

# Execute
if [[ -n "$TASKS_TO_EXECUTE" ]] && [[ "$TASKS_TO_EXECUTE" != "" ]]; then
    echo ""
    echo -e "${MAGENTA}═══ PHASE 3: Execution ═══${NC}"
    
    prompt=$(find "$BUNDLE_PATH/prompts" -name "07*.md" 2>/dev/null | head -1)
    [[ -n "$prompt" ]] && claude -p "$(cat "$prompt")" --allowedTools Edit,Write,Bash
    
    for task_prompt in "$FEATURE_DIR/prompts/"[0-9]*.md; do
        [[ ! -f "$task_prompt" ]] && continue
        TASK_ID=$(basename "$task_prompt" | grep -oE '^[0-9]+')
        
        if [[ "$TASKS_TO_EXECUTE" == "all" ]] || [[ ",$TASKS_TO_EXECUTE," == *",$TASK_ID,"* ]]; then
            echo -e "${BLUE}→ Task $TASK_ID${NC}"
            claude -p "$(cat "$task_prompt")" --allowedTools Edit,Write,Bash
            echo -e "${GREEN}✓${NC}"
        fi
    done
fi

# Summary
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           COMPLETE                                           ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Output: $FEATURE_DIR/"

log_to_planning "COMPLETED" "Feature: \`$FEATURE_DIR/\`
Executed: ${TASKS_TO_EXECUTE:-none}
Deferred: $(echo "$TASKS_TO_DEFER" | grep -c "Task" 2>/dev/null || echo 0)"

echo -e "${GREEN}Logged to .ai/ledger/PLANNING.md${NC}"
