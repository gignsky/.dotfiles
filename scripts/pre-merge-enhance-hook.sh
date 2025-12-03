#!/bin/bash

# =============================================================================
# SCOTTY'S PRE-MERGE COMMIT ENHANCEMENT HOOK
# =============================================================================
# Git hook for automatic commit message enhancement before merges
# Triggered on: git merge, git rebase, git pull with merge

# Source the commit enhancement library
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel)"
SCRIPTS_DIR="${REPO_ROOT}/scripts"

if [ -f "${SCRIPTS_DIR}/commit-enhance-lib.sh" ]; then
    source "${SCRIPTS_DIR}/commit-enhance-lib.sh"
else
    echo "Warning: Commit enhancement library not found at ${SCRIPTS_DIR}/commit-enhance-lib.sh" >&2
    exit 0  # Don't fail the hook, just skip enhancement
fi

# Set automated context
export AUTOMATED_COMMIT=true

# Hook configuration
ENHANCE_MERGES=${SCOTTY_ENHANCE_MERGES:-true}
ENHANCE_REBASES=${SCOTTY_ENHANCE_REBASES:-true}
SKIP_ENHANCEMENT=${SCOTTY_SKIP_ENHANCEMENT:-false}

# Skip if explicitly disabled
if [ "$SKIP_ENHANCEMENT" = "true" ]; then
    exit 0
fi

# Get current operation type
operation_type=""
if [ -f "${REPO_ROOT}/.git/MERGE_HEAD" ]; then
    operation_type="merge"
elif [ -d "${REPO_ROOT}/.git/rebase-merge" ] || [ -d "${REPO_ROOT}/.git/rebase-apply" ]; then
    operation_type="rebase"
fi

# Check if we should process this operation
case "$operation_type" in
    merge)
        if [ "$ENHANCE_MERGES" != "true" ]; then
            exit 0
        fi
        ;;
    rebase)
        if [ "$ENHANCE_REBASES" != "true" ]; then
            exit 0
        fi
        ;;
    *)
        # Not a merge or rebase, skip
        exit 0
        ;;
esac

# Function to enhance commit message file
enhance_commit_file() {
    local commit_msg_file="$1"
    local operation="$2"
    
    if [ ! -f "$commit_msg_file" ]; then
        return 0
    fi
    
    # Read original message
    local original_message
    original_message=$(cat "$commit_msg_file")
    
    # Skip if empty or commented out
    if [ -z "$original_message" ] || echo "$original_message" | grep -q "^#"; then
        return 0
    fi
    
    # Skip if already enhanced
    if echo "$original_message" | grep -qE "(Chief-Engineer|Captain|Auto-System):"; then
        return 0
    fi
    
    # Enhance the message
    local enhanced_message
    enhanced_message=$(process_commit_message "$original_message" "git-$operation" "$REPO_ROOT" true)
    
    if [ $? -eq 0 ]; then
        # Write enhanced message back to file
        echo "$enhanced_message" > "$commit_msg_file"
        
        # Log the enhancement
        scotty_create_log "COMMIT ENHANCED" "Auto-enhanced $operation commit message following Lord Gig's Standards of Commitence" "note"
    else
        # Log validation failure but don't fail the hook
        scotty_create_log "COMMIT VALIDATION WARNING" "Commit message validation failed during $operation, proceeding with original message" "note"
    fi
}

# Process based on hook type
case "${BASH_SOURCE[0]}" in
    *pre-merge-commit*)
        # Pre-merge commit hook
        if [ "$#" -eq 1 ]; then
            enhance_commit_file "$1" "merge"
        fi
        ;;
    *prepare-commit-msg*)
        # Prepare commit message hook
        if [ "$#" -ge 1 ]; then
            enhance_commit_file "$1" "${2:-commit}"
        fi
        ;;
    *)
        # Called directly, enhance based on current git state
        if [ -f "${REPO_ROOT}/.git/COMMIT_EDITMSG" ]; then
            enhance_commit_file "${REPO_ROOT}/.git/COMMIT_EDITMSG" "direct"
        fi
        ;;
esac

exit 0
