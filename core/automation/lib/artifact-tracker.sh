#!/usr/bin/env bash
# artifact-tracker.sh - Library for tracking automation artifacts
#
# Source this in automation scripts:
#   source "$(dirname "$0")/lib/artifact-tracker.sh"
#
# Usage:
#   init_session "align-repo.sh"
#   register_artifact "file" ".ai/_scratch/PLAN.md" "generate_plan()"
#   complete_session "completed"

# Registry file location
ARTIFACT_REGISTRY="${ARTIFACT_REGISTRY:-${REPO_ROOT:-.}/.ai/_scratch/.artifact-registry.json}"

# Current session
CURRENT_SESSION=""

init_session() {
    local script_name="$1"
    CURRENT_SESSION=$(date +%Y%m%d-%H%M%S)
    
    if [[ ! -f "$ARTIFACT_REGISTRY" ]]; then
        mkdir -p "$(dirname "$ARTIFACT_REGISTRY")"
        echo '{"version":"1.0","sessions":{}}' > "$ARTIFACT_REGISTRY"
    fi
    
    local tmp=$(mktemp)
    jq --arg sid "$CURRENT_SESSION" \
       --arg script "$script_name" \
       --arg created "$(date -Iseconds)" \
       '.sessions[$sid] = {"script":$script,"created":$created,"status":"active","artifacts":[]}' \
       "$ARTIFACT_REGISTRY" > "$tmp" && mv "$tmp" "$ARTIFACT_REGISTRY"
    
    echo "$CURRENT_SESSION"
}

register_artifact() {
    local type="$1" path="$2" func="${3:-unknown}"
    [[ -z "$CURRENT_SESSION" || ! -f "$ARTIFACT_REGISTRY" ]] && return 1
    
    local tmp=$(mktemp)
    jq --arg sid "$CURRENT_SESSION" --arg p "$path" --arg t "$type" --arg f "$func" \
       '.sessions[$sid].artifacts += [{"path":$p,"type":$t,"function":$f}]' \
       "$ARTIFACT_REGISTRY" > "$tmp" && mv "$tmp" "$ARTIFACT_REGISTRY"
}

complete_session() {
    local status="${1:-completed}"
    [[ -z "$CURRENT_SESSION" || ! -f "$ARTIFACT_REGISTRY" ]] && return 1
    
    local tmp=$(mktemp)
    jq --arg sid "$CURRENT_SESSION" --arg s "$status" \
       '.sessions[$sid].status = $s' \
       "$ARTIFACT_REGISTRY" > "$tmp" && mv "$tmp" "$ARTIFACT_REGISTRY"
}

list_session_artifacts() {
    local session="${1:-$CURRENT_SESSION}"
    [[ ! -f "$ARTIFACT_REGISTRY" ]] && return 1
    jq -r --arg sid "$session" '.sessions[$sid].artifacts[]|"\(.type)\t\(.path)"' "$ARTIFACT_REGISTRY"
}

clean_session() {
    local session="${1:-$CURRENT_SESSION}"
    [[ ! -f "$ARTIFACT_REGISTRY" ]] && return 1
    
    while IFS=$'\t' read -r type path; do
        local fp="${REPO_ROOT:-.}/$path"
        [[ "$type" == "directory" && -d "$fp" ]] && rm -rf "$fp"
        [[ "$type" == "file" && -f "$fp" ]] && rm -f "$fp"
    done < <(list_session_artifacts "$session")
    
    complete_session "destroyed"
}
