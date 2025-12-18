#!/usr/bin/env bash
set -euo pipefail

# cleanup.sh - Unified artifact cleanup based on FUNCTION_MANIFEST.md
#
# Usage:
#   cleanup.sh                    # Interactive menu
#   cleanup.sh --all              # Clean everything
#   cleanup.sh --alignment        # Clean alignment artifacts
#   cleanup.sh --features         # Clean feature artifacts
#   cleanup.sh --research         # Clean research artifacts
#   cleanup.sh --prompts          # Clean cloud architect artifacts
#   cleanup.sh --session <ID>     # Clean specific session
#   cleanup.sh --dry-run          # Show what would be cleaned

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
TARGET=""
SESSION=""

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Unified cleanup for automation artifacts.

Options:
    --all              Clean ALL scratch artifacts
    --alignment        Clean alignment plans only
    --features         Clean feature directories only
    --research         Clean research directories only
    --prompts          Clean cloud architect prompts only
    --session <ID>     Clean specific session (e.g., 20251218-030842)
    --dry-run          Show what would be cleaned
    -h, --help         Show this help

Examples:
    cleanup.sh --alignment --dry-run   # Preview alignment cleanup
    cleanup.sh --session 20251218      # Clean all from Dec 18
    cleanup.sh --all                   # Nuclear option
EOF
    exit 0
}

log() {
    local level="$1"; shift
    case "$level" in
        INFO)  echo -e "${BLUE}ℹ${NC} $*" ;;
        OK)    echo -e "${GREEN}✓${NC} $*" ;;
        WARN)  echo -e "${YELLOW}⚠${NC} $*" ;;
        DEL)   echo -e "${RED}✗${NC} $*" ;;
        DRY)   echo -e "${YELLOW}[DRY]${NC} Would remove: $*" ;;
    esac
}

remove_item() {
    local item="$1"
    if [[ "$DRY_RUN" == true ]]; then
        log DRY "$item"
    else
        if [[ -d "$item" ]]; then
            rm -rf "$item"
            log DEL "Removed directory: $item"
        elif [[ -f "$item" ]]; then
            rm -f "$item"
            log DEL "Removed file: $item"
        fi
    fi
}

clean_alignment() {
    log INFO "Cleaning alignment artifacts..."
    local count=0
    
    for f in "$REPO_ROOT/.ai/_scratch/ALIGNMENT_PLAN"*.md; do
        [[ -f "$f" ]] && { remove_item "$f"; ((++count)); }
    done
    
    for f in "$REPO_ROOT/.ai/_scratch/alignment-"*/; do
        [[ -d "$f" ]] && { remove_item "$f"; ((++count)); }
    done
    
    [[ -f "$REPO_ROOT/.ai/_scratch/DEFERRED_ALIGNMENT.md" ]] && {
        remove_item "$REPO_ROOT/.ai/_scratch/DEFERRED_ALIGNMENT.md"
        ((++count))
    }
    
    log OK "Alignment: $count items"
}

clean_features() {
    log INFO "Cleaning feature artifacts..."
    local count=0
    
    for d in "$REPO_ROOT/.ai/_scratch/feature-"*/; do
        [[ -d "$d" ]] && { remove_item "$d"; ((++count)); }
    done
    
    [[ -f "$REPO_ROOT/.ai/_scratch/user-request.md" ]] && {
        remove_item "$REPO_ROOT/.ai/_scratch/user-request.md"
        ((++count))
    }
    
    [[ -f "$REPO_ROOT/.ai/_scratch/DEFERRED_WORK.md" ]] && {
        remove_item "$REPO_ROOT/.ai/_scratch/DEFERRED_WORK.md"
        ((++count))
    }
    
    log OK "Features: $count items"
}

clean_research() {
    log INFO "Cleaning research artifacts..."
    local count=0
    
    for d in "$REPO_ROOT/.ai/_scratch/research-"*/; do
        [[ -d "$d" ]] && { remove_item "$d"; ((++count)); }
    done
    
    log OK "Research: $count items"
}

clean_prompts() {
    log INFO "Cleaning cloud architect artifacts..."
    local count=0
    
    if [[ -d "$REPO_ROOT/.ai/_scratch/prompts" ]]; then
        remove_item "$REPO_ROOT/.ai/_scratch/prompts"
        ((++count))
    fi
    
    log OK "Prompts: $count items"
}

clean_session() {
    local session="$1"
    log INFO "Cleaning session: $session"
    local count=0
    
    # Find all files/dirs containing session ID
    while IFS= read -r -d '' item; do
        remove_item "$item"
        ((++count))
    done < <(find "$REPO_ROOT/.ai/_scratch" -name "*$session*" -print0 2>/dev/null)
    
    log OK "Session $session: $count items"
}

clean_all() {
    log WARN "Cleaning ALL scratch artifacts..."
    
    clean_alignment
    clean_features
    clean_research
    clean_prompts
    
    # Also clean misc .md files (except README)
    for f in "$REPO_ROOT/.ai/_scratch/"*.md; do
        [[ -f "$f" ]] && [[ "$(basename "$f")" != "README.md" ]] && remove_item "$f"
    done
    
    # Clean task logs
    [[ -d "$REPO_ROOT/.ai/_scratch/task-logs" ]] && {
        rm -rf "$REPO_ROOT/.ai/_scratch/task-logs"/*
        log DEL "Cleared task-logs/"
    }
    
    log OK "All artifacts cleaned"
}

show_menu() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    Artifact Cleanup                          ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Show current state
    local alignment_count=$(ls -1 "$REPO_ROOT/.ai/_scratch/ALIGNMENT_PLAN"*.md 2>/dev/null | wc -l || echo 0)
    local feature_count=$(ls -1d "$REPO_ROOT/.ai/_scratch/feature-"*/ 2>/dev/null | wc -l || echo 0)
    local research_count=$(ls -1d "$REPO_ROOT/.ai/_scratch/research-"*/ 2>/dev/null | wc -l || echo 0)
    local prompts_exists=$([[ -d "$REPO_ROOT/.ai/_scratch/prompts" ]] && echo "yes" || echo "no")
    
    echo "Current artifacts:"
    echo "  1) Alignment plans:  $alignment_count"
    echo "  2) Feature dirs:     $feature_count"
    echo "  3) Research dirs:    $research_count"
    echo "  4) Prompts dir:      $prompts_exists"
    echo "  5) ALL of the above"
    echo "  q) Quit"
    echo ""
    read -p "Clean which? [1-5/q]: " choice
    
    case "$choice" in
        1) clean_alignment ;;
        2) clean_features ;;
        3) clean_research ;;
        4) clean_prompts ;;
        5) clean_all ;;
        q|Q) exit 0 ;;
        *) echo "Invalid choice"; exit 1 ;;
    esac
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --all) TARGET="all"; shift ;;
        --alignment) TARGET="alignment"; shift ;;
        --features) TARGET="features"; shift ;;
        --research) TARGET="research"; shift ;;
        --prompts) TARGET="prompts"; shift ;;
        --session) SESSION="$2"; shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown: $1"; usage ;;
    esac
done

cd "$REPO_ROOT"

# Execute
if [[ -n "$SESSION" ]]; then
    clean_session "$SESSION"
elif [[ -n "$TARGET" ]]; then
    case "$TARGET" in
        all) clean_all ;;
        alignment) clean_alignment ;;
        features) clean_features ;;
        research) clean_research ;;
        prompts) clean_prompts ;;
    esac
else
    show_menu
fi
