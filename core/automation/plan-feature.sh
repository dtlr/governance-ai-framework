#!/usr/bin/env bash
set -euo pipefail

# plan-feature.sh - Feature planning + standalone research
#
# DEFAULT: Always dry-run first and generate documentation
# Then user chooses: accept | defer | destroy
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
BOLD='\033[1m'
NC='\033[0m'

# Modes and defaults - DRY_RUN IS TRUE BY DEFAULT
MODE="feature"  # feature, research
DRY_RUN=true
APPLY=false
DEFER=false
DESTROY=false
INTERACTIVE=true
REQUEST=""
EXECUTE_SCOPE=""
SESSION_ID=$(date +%Y%m%d-%H%M%S)
START_TIME=$(date +%s)

# Tracking
declare -a PLAN_TASKS=()
FEATURE_DIR=""
PLAN_FILE=""

usage() {
    cat << EOF
Usage: $(basename "$0") [MODE] [OPTIONS]

${BOLD}Feature planning - always generates documentation first.${NC}

${CYAN}Workflow:${NC}
    1. Run with request → generates FEATURE.md, PDR.md, tasks
    2. Review the plan
    3. Choose: --apply | --defer | --destroy

${CYAN}Modes:${NC}
    --research          Deep research mode (standalone, no repo changes)
    (default)           Feature planning with implementation

${CYAN}Research Mode Options:${NC}
    --question "text"   The research question
    --output FILE       Output file (default: .ai/_scratch/research-SESSION.md)

${CYAN}Feature Mode Options:${NC}
    --request "text"    The feature/change request
    --apply             Execute the generated plan
    --apply-scope SCOPE Execute scope: all, p0-p1, p0, custom:01,02
    --defer             Create GitHub issue for later
    --destroy           Clean up all generated files
    --force             Skip documentation (dangerous)

${CYAN}Common Options:${NC}
    --non-interactive   Don't prompt
    -h, --help          Show this help

${CYAN}Examples:${NC}
    # Step 1: Generate plan (default)
    $(basename "$0") --request "Add Redis caching"
    
    # Step 2a: Accept and execute all
    $(basename "$0") --apply
    
    # Step 2a: Accept critical only
    $(basename "$0") --apply --apply-scope p0-p1
    
    # Step 2b: Defer to backlog
    $(basename "$0") --defer
    
    # Step 2c: Discard everything
    $(basename "$0") --destroy
    
    # Research only (no implementation)
    $(basename "$0") --research --question "Best way to manage golden Linux images on Azure"
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
        PLAN)   echo -e "${CYAN}📋${NC} $*" ;;
        DRY)    echo -e "${YELLOW}[DRY-RUN]${NC} $*" ;;
    esac
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

# Create GitHub issue for deferred work
create_defer_issue() {
    local title="$1"
    local body="$2"
    
    if command -v gh &> /dev/null; then
        local issue_url=$(gh issue create \
            --title "🔮 Deferred: $title" \
            --body "$body" \
            --label "ai-deferred,backlog" 2>/dev/null || echo "")
        
        if [[ -n "$issue_url" ]]; then
            echo -e "${GREEN}✓ GitHub Issue: $issue_url${NC}"
            echo "$issue_url" > "$REPO_ROOT/.ai/_scratch/DEFERRED_ISSUE.txt"
            return 0
        fi
    fi
    
    # Fallback to local file
    echo "$body" > "$REPO_ROOT/.ai/_scratch/DEFERRED_WORK.md"
    echo -e "${YELLOW}Saved: .ai/_scratch/DEFERRED_WORK.md${NC}"
}

# Find latest feature directory
find_latest_feature() {
    ls -td "$REPO_ROOT/.ai/_scratch/feature-"*/ 2>/dev/null | head -1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --research) MODE="research"; shift ;;
        --question) REQUEST="$2"; shift 2 ;;
        --request) REQUEST="$2"; shift 2 ;;
        --output) OUTPUT_FILE="$2"; shift 2 ;;
        --apply) APPLY=true; DRY_RUN=false; shift ;;
        --apply-scope) EXECUTE_SCOPE="$2"; shift 2 ;;
        --defer) DEFER=true; shift ;;
        --destroy) DESTROY=true; shift ;;
        --force) DRY_RUN=false; shift ;;
        --non-interactive) INTERACTIVE=false; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown: $1"; usage ;;
    esac
done

# Setup
mkdir -p "$REPO_ROOT/.ai/_scratch"
mkdir -p "$REPO_ROOT/.ai/ledger"

# ═══════════════════════════════════════════════════════════════════════════════
# DESTROY MODE - Clean up generated files
# ═══════════════════════════════════════════════════════════════════════════════
if [[ "$DESTROY" == true ]]; then
    echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                    DESTROY MODE                              ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    found=0
    
    # Remove feature directories
    for d in "$REPO_ROOT/.ai/_scratch/feature-"*/; do
        [[ -d "$d" ]] && { echo "  Removing: $d"; rm -rf "$d"; ((++found)); }
    done
    
    # Remove research directories
    for d in "$REPO_ROOT/.ai/_scratch/research-"*/; do
        [[ -d "$d" ]] && { echo "  Removing: $d"; rm -rf "$d"; ((++found)); }
    done
    
    # Remove plan files
    for f in "$REPO_ROOT/.ai/_scratch/"*.md; do
        [[ -f "$f" ]] && [[ "$(basename "$f")" != "README.md" ]] && { 
            echo "  Removing: $f"; rm -f "$f"; ((++found))
        }
    done
    
    # Remove user request
    rm -f "$REPO_ROOT/.ai/_scratch/user-request.md" 2>/dev/null && ((++found)) || true
    
    if [[ $found -eq 0 ]]; then
        echo -e "${YELLOW}No planning artifacts found to clean up.${NC}"
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
    
    FEATURE_DIR=$(find_latest_feature)
    
    if [[ -z "$FEATURE_DIR" ]]; then
        log ERROR "No feature plan found. Run with --request first to generate one."
        exit 1
    fi
    
    FEATURE_NAME=$(basename "$FEATURE_DIR")
    
    # Build issue body from generated artifacts
    ISSUE_BODY="## Feature Deferred: $FEATURE_NAME

**Session**: \`$SESSION_ID\`
**Generated**: $(date -Iseconds)

"
    
    # Include FEATURE.md if exists
    if [[ -f "$FEATURE_DIR/FEATURE.md" ]]; then
        ISSUE_BODY+="### Feature Specification
\`\`\`markdown
$(head -50 "$FEATURE_DIR/FEATURE.md")
\`\`\`

"
    fi
    
    # Include task list
    if [[ -f "$FEATURE_DIR/tasks.json" ]]; then
        ISSUE_BODY+="### Tasks
$(jq -r '.tasks[] | "- [ ] [\(.priority)] \(.name)"' "$FEATURE_DIR/tasks.json" 2>/dev/null || echo "See tasks.json")

"
    fi
    
    ISSUE_BODY+="### Context
Artifacts: \`$FEATURE_DIR/\`

To resume: \`plan-feature.sh --apply\`
"
    
    create_defer_issue "$FEATURE_NAME" "$ISSUE_BODY"
    log_to_planning "DEFERRED" "Feature: \`$FEATURE_DIR/\`"
    exit 0
fi

# ═══════════════════════════════════════════════════════════════════════════════
# APPLY MODE - Execute existing plan
# ═══════════════════════════════════════════════════════════════════════════════
if [[ "$APPLY" == true ]] && [[ -z "$REQUEST" ]]; then
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                  EXECUTING PLAN                              ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    FEATURE_DIR=$(find_latest_feature)
    
    if [[ -z "$FEATURE_DIR" ]]; then
        log ERROR "No feature plan found. Run with --request first."
        exit 1
    fi
    
    log INFO "Executing: $FEATURE_DIR"
    
    # Default to all if no scope specified
    EXECUTE_SCOPE="${EXECUTE_SCOPE:-all}"
    
    # Check for claude CLI
    if ! command -v claude &> /dev/null; then
        log ERROR "claude CLI not found"
        exit 1
    fi
    
    # Find governance bundles
    GOVERNANCE_PATH=""
    [[ -d "$REPO_ROOT/.governance/ai" ]] && GOVERNANCE_PATH="$REPO_ROOT/.governance/ai"
    BUNDLE_PATH="${GOVERNANCE_PATH:-$SCRIPT_DIR/..}/core/templates/golden-image/.ai/bundles/feature-planning-v1"
    
    # Generate prompts if not already done
    if [[ ! -d "$FEATURE_DIR/prompts" ]] || [[ -z "$(ls -A "$FEATURE_DIR/prompts" 2>/dev/null)" ]]; then
        log STEP "Generating execution prompts..."
        prompt=$(find "$BUNDLE_PATH/prompts" -name "07*.md" 2>/dev/null | head -1)
        if [[ -n "$prompt" ]]; then
            claude -p "$(cat "$prompt")" --allowedTools Edit,Write,Bash 2>&1 | tee "$FEATURE_DIR/07_generate.log"
        fi
    fi
    
    # Determine which tasks to execute
    TASKS_TO_EXECUTE=""
    TASKS_TO_DEFER=""
    
    case "$EXECUTE_SCOPE" in
        all) 
            TASKS_TO_EXECUTE="all" 
            ;;
        p0-p1)
            TASKS_TO_EXECUTE=$(jq -r '.tasks[] | select(.priority == "P0" or .priority == "P1") | .id' "$FEATURE_DIR/tasks.json" 2>/dev/null | tr '\n' ',' | sed 's/,$//')
            TASKS_TO_DEFER=$(jq -r '.tasks[] | select(.priority == "P2" or .priority == "P3") | "- [\(.priority)] \(.name)"' "$FEATURE_DIR/tasks.json" 2>/dev/null)
            ;;
        p0)
            TASKS_TO_EXECUTE=$(jq -r '.tasks[] | select(.priority == "P0") | .id' "$FEATURE_DIR/tasks.json" 2>/dev/null | tr '\n' ',' | sed 's/,$//')
            TASKS_TO_DEFER=$(jq -r '.tasks[] | select(.priority != "P0") | "- [\(.priority)] \(.name)"' "$FEATURE_DIR/tasks.json" 2>/dev/null)
            ;;
        custom:*)
            TASKS_TO_EXECUTE="${EXECUTE_SCOPE#custom:}"
            ;;
    esac
    
    # Execute prompts
    executed=0
    for task_prompt in "$FEATURE_DIR/prompts/"[0-9]*.md; do
        [[ ! -f "$task_prompt" ]] && continue
        TASK_ID=$(basename "$task_prompt" | grep -oE '^[0-9]+')
        
        if [[ "$TASKS_TO_EXECUTE" == "all" ]] || [[ ",$TASKS_TO_EXECUTE," == *",$TASK_ID,"* ]]; then
            log STEP "Task $TASK_ID: $(basename "$task_prompt" .md)"
            claude -p "$(cat "$task_prompt")" --allowedTools Edit,Write,Bash 2>&1 | tee "$FEATURE_DIR/exec_${TASK_ID}.log"
            log OK "Task $TASK_ID complete"
            ((++executed))
        fi
    done
    
    # Handle deferred tasks
    if [[ -n "$TASKS_TO_DEFER" ]]; then
        echo ""
        log WARN "Deferred tasks:"
        echo "$TASKS_TO_DEFER"
        
        if [[ "$INTERACTIVE" == true ]]; then
            read -p "Create GitHub issue for deferred tasks? [Y/n]: " create_issue
            if [[ ! "$create_issue" =~ ^[Nn] ]]; then
                create_defer_issue "$(basename "$FEATURE_DIR") - Remaining" "## Deferred Tasks

$TASKS_TO_DEFER

### Context
Original feature: \`$FEATURE_DIR/\`"
            fi
        fi
    fi
    
    # Summary
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                 EXECUTION COMPLETE                           ║${NC}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║  Executed: $executed task(s)                                       ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    
    log_to_planning "EXECUTED" "Tasks: $executed | Scope: $EXECUTE_SCOPE"
    
    # Cleanup option
    if [[ "$INTERACTIVE" == true ]]; then
        echo ""
        read -p "Clean up planning artifacts? [y/N]: " cleanup
        if [[ "$cleanup" =~ ^[Yy] ]]; then
            rm -rf "$FEATURE_DIR"
            log OK "Cleaned up $FEATURE_DIR"
        fi
    fi
    
    exit 0
fi

# ═══════════════════════════════════════════════════════════════════════════════
# PLANNING MODE (default) - Generate documentation
# ═══════════════════════════════════════════════════════════════════════════════

# Handle input
if [[ -n "$REQUEST" ]]; then
    echo "$REQUEST" > "$REPO_ROOT/.ai/_scratch/user-request.md"
elif [[ ! -f "$REPO_ROOT/.ai/_scratch/user-request.md" ]]; then
    echo -e "${YELLOW}Enter your question/request (Ctrl+D when done):${NC}"
    cat > "$REPO_ROOT/.ai/_scratch/user-request.md"
fi

REQUEST_PREVIEW=$(head -1 "$REPO_ROOT/.ai/_scratch/user-request.md" | cut -c1-50)

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
if [[ "$MODE" == "research" ]]; then
echo -e "${BLUE}║         Deep Research Mode (Documentation Only)              ║${NC}"
else
echo -e "${BLUE}║         Feature Planning (Documentation Only)                ║${NC}"
fi
echo -e "${BLUE}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BLUE}║  Session: $SESSION_ID                              ║${NC}"
echo -e "${BLUE}║  Input:   ${REQUEST_PREVIEW}...${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check for claude CLI
if ! command -v claude &> /dev/null; then
    log ERROR "claude CLI not found"
    exit 1
fi

# Find governance
GOVERNANCE_PATH=""
[[ -d "$REPO_ROOT/.governance/ai" ]] && GOVERNANCE_PATH="$REPO_ROOT/.governance/ai"
BUNDLE_PATH="${GOVERNANCE_PATH:-$SCRIPT_DIR/..}/core/templates/golden-image/.ai/bundles/feature-planning-v1"

# ═══════════════════════════════════════════════════════════════════════════════
# RESEARCH MODE
# ═══════════════════════════════════════════════════════════════════════════════
if [[ "$MODE" == "research" ]]; then
    OUTPUT_DIR="$REPO_ROOT/.ai/_scratch/research-$SESSION_ID"
    mkdir -p "$OUTPUT_DIR"
    
    log STEP "Creating research plan..."
    prompt="$BUNDLE_PATH/prompts/00a_research_question.md"
    if [[ -f "$prompt" ]]; then
        claude -p "$(cat "$prompt")" --allowedTools Edit,Write,Bash 2>&1 | tee "$OUTPUT_DIR/00_plan.log"
    else
        claude -p "You are a Cloud Architect. Analyze this question and create a research plan:

$(cat "$REPO_ROOT/.ai/_scratch/user-request.md")

Output to .ai/_scratch/research-$SESSION_ID/research-plan.md with:
1. Question type (ARCHITECTURE/COMPARISON/BEST_PRACTICE/IMPLEMENTATION)
2. Sources to consult
3. Sub-questions
4. Expected output format" --allowedTools Edit,Write,Bash 2>&1 | tee "$OUTPUT_DIR/00_plan.log"
    fi
    
    log STEP "Executing research..."
    prompt="$BUNDLE_PATH/prompts/00b_deep_research.md"
    if [[ -f "$prompt" ]]; then
        claude -p "$(cat "$prompt")" --allowedTools Edit,Write,Bash 2>&1 | tee "$OUTPUT_DIR/01_research.log"
    else
        claude -p "Execute research for: $(cat "$REPO_ROOT/.ai/_scratch/user-request.md")

Output to .ai/_scratch/research-$SESSION_ID/research-findings.md with:
1. Executive Summary
2. TL;DR Recommendation
3. Options comparison
4. Pros/Cons
5. Cost estimates
6. Security considerations
7. Sources
8. Next steps" --allowedTools Edit,Write,Bash 2>&1 | tee "$OUTPUT_DIR/01_research.log"
    fi
    
    # Summary
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              RESEARCH DOCUMENTATION COMPLETE                 ║${NC}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║  Output: $OUTPUT_DIR/${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo "  cat $OUTPUT_DIR/research-findings.md  # View results"
    echo "  plan-feature.sh --destroy             # Discard"
    
    log_to_planning "RESEARCH_COMPLETE" "Output: \`$OUTPUT_DIR/\`"
    exit 0
fi

# ═══════════════════════════════════════════════════════════════════════════════
# FEATURE PLANNING (generates documentation only)
# ═══════════════════════════════════════════════════════════════════════════════

FEATURE_DIR="$REPO_ROOT/.ai/_scratch/feature-$SESSION_ID"
mkdir -p "$FEATURE_DIR/research" "$FEATURE_DIR/prompts"

log INFO "Output directory: $FEATURE_DIR"
echo ""

echo -e "${MAGENTA}═══ PHASE 1: Research & Analysis ═══${NC}"
for num in 00 01 02 03; do
    prompt=$(find "$BUNDLE_PATH/prompts" -name "${num}_*.md" 2>/dev/null | head -1)
    [[ -z "$prompt" ]] && continue
    [[ "$(basename "$prompt")" == "00a_"* ]] && continue
    [[ "$(basename "$prompt")" == "00b_"* ]] && continue
    
    PROMPT_NAME=$(basename "$prompt" .md)
    log STEP "$PROMPT_NAME"
    
    if claude -p "$(cat "$prompt")" --allowedTools Edit,Write,Bash 2>&1 | tee "$FEATURE_DIR/${PROMPT_NAME}.log"; then
        log OK "$PROMPT_NAME"
    else
        log ERROR "Failed at: $PROMPT_NAME"
        log_to_planning "FAILED" "Failed at: $PROMPT_NAME"
        exit 1
    fi
done

echo ""
echo -e "${MAGENTA}═══ PHASE 2: Generate Specifications ═══${NC}"
for num in 04 05; do
    prompt=$(find "$BUNDLE_PATH/prompts" -name "${num}_*.md" 2>/dev/null | head -1)
    [[ -z "$prompt" ]] && continue
    PROMPT_NAME=$(basename "$prompt" .md)
    log STEP "$PROMPT_NAME"
    claude -p "$(cat "$prompt")" --allowedTools Edit,Write,Bash 2>&1 | tee "$FEATURE_DIR/${PROMPT_NAME}.log"
    log OK "$PROMPT_NAME"
done

echo ""
echo -e "${MAGENTA}═══ PHASE 3: Task Decomposition ═══${NC}"
for num in 06 06b; do
    prompt=$(find "$BUNDLE_PATH/prompts" -name "${num}*.md" 2>/dev/null | head -1)
    [[ -z "$prompt" ]] && continue
    PROMPT_NAME=$(basename "$prompt" .md)
    log STEP "$PROMPT_NAME"
    claude -p "$(cat "$prompt")" --allowedTools Edit,Write,Bash 2>&1 | tee "$FEATURE_DIR/${PROMPT_NAME}.log"
    log OK "$PROMPT_NAME"
done

# Move generated artifacts to feature dir
for f in FEATURE.md PDR.md tasks.json REVIEW.md; do
    [[ -f "$REPO_ROOT/.ai/_scratch/$f" ]] && mv "$REPO_ROOT/.ai/_scratch/$f" "$FEATURE_DIR/"
done

# Summary
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           DOCUMENTATION COMPLETE                             ║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║  Feature: $FEATURE_DIR/${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Show task summary if available
if [[ -f "$FEATURE_DIR/tasks.json" ]]; then
    echo -e "${CYAN}═══ TASK SUMMARY ═══${NC}"
    jq -r '.tasks[] | "  [\(.priority)] \(.id): \(.name)"' "$FEATURE_DIR/tasks.json" 2>/dev/null || cat "$FEATURE_DIR/tasks.json"
    echo ""
fi

echo -e "${CYAN}Generated:${NC}"
ls -la "$FEATURE_DIR/"*.md "$FEATURE_DIR/"*.json 2>/dev/null | awk '{print "  " $NF}'
echo ""

echo -e "${CYAN}Next steps:${NC}"
echo "  plan-feature.sh --apply                # Execute all tasks"
echo "  plan-feature.sh --apply --apply-scope p0-p1  # Execute P0+P1 only"
echo "  plan-feature.sh --defer                # Create backlog issue"
echo "  plan-feature.sh --destroy              # Discard plan"

log_to_planning "PLANNED" "Feature: \`$FEATURE_DIR/\`
Request: \`$REQUEST_PREVIEW...\`"
