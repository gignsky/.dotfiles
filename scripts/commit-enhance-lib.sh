#!/bin/bash

# =============================================================================
# SCOTTY'S COMMIT ENHANCEMENT LIBRARY
# =============================================================================
# Automatic commit message enhancement following Gigi's Commitus standards
# Integrates with conventional commits while adding technical context and signatures

# Source the existing logging library for git state functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/scotty-logging-lib.sh"

# Agent identification and signatures
SCOTTY_SIGNATURE="Chief-Engineer: Scotty"
AUTO_SYSTEM_PREFIX="Auto-System:"
CAPTAIN_SIGNATURE="Captain: Lord-Gig"

# Get current timestamp in Scotty's preferred stardate format
get_stardate_timestamp() {
    date '+%Y.%m.%d-%H:%M'
}

# Determine who/what is making this commit
get_commit_agent() {
    local script_name="${1:-unknown}"
    
    # Check if we're in an automated context
    if [ -n "$AUTOMATED_COMMIT" ] || [ -n "$CI" ]; then
        echo "${AUTO_SYSTEM_PREFIX} ${script_name}"
    elif [ -n "$SCOTTY_AGENT" ]; then
        echo "$SCOTTY_SIGNATURE"
    else
        echo "$CAPTAIN_SIGNATURE"
    fi
}

# Extract conventional commit components from a message
parse_commit_message() {
    local message="$1"
    local type=""
    local scope=""
    local description=""
    local body=""
    local footers=""
    
    # Extract type and scope from first line: type(scope): description
    if [[ "$message" =~ ^([a-z]+)(\([^)]+\))?: (.+)$ ]]; then
        type="${BASH_REMATCH[1]}"
        scope="${BASH_REMATCH[2]}"
        description="${BASH_REMATCH[3]}"
        # Remove parentheses from scope
        scope="${scope//[()]/}"
    else
        # Fallback: treat entire first line as description
        description=$(echo "$message" | head -n1)
    fi
    
    # Extract body and footers
    if [ "$(echo "$message" | wc -l)" -gt 1 ]; then
        body=$(echo "$message" | sed -n '3,$p' | sed '/^[A-Za-z-]*:/,$d')
        footers=$(echo "$message" | sed -n '/^[A-Za-z-]*:/,$p')
    fi
    
    echo "${type}|${scope}|${description}|${body}|${footers}"
}

# Enhance a commit message with technical context
enhance_commit_message() {
    local original_message="$1"
    local script_name="${2:-manual}"
    local repo_dir="${3:-$(pwd)}"
    
    cd "$repo_dir" || return 1
    
    # Parse the original message
    local parsed
    parsed=$(parse_commit_message "$original_message")
    IFS='|' read -r type scope description body footers <<< "$parsed"
    
    # Get current git and system state
    local git_info
    git_info=$(get_git_state "$repo_dir")
    IFS='|' read -r git_commit git_branch git_status flake_lock_hash git_short_commit <<< "$git_info"
    
    # Get generation information if available
    local generation_info=""
    local current_gen
    current_gen=$(get_home_manager_generation)
    if [ "$current_gen" != "unknown" ]; then
        generation_info="gen $current_gen"
    fi
    
    # Build enhanced description with technical context
    local enhanced_description="$description"
    local technical_context=""
    
    # Add git state context if tree is not clean
    if [ "$git_status" != "clean" ]; then
        technical_context="${technical_context} (${git_status})"
    fi
    
    # Add generation info if available
    if [ -n "$generation_info" ]; then
        technical_context="${technical_context} ($generation_info)"
    fi
    
    # Add branch context if not on main/master
    if [ "$git_branch" != "main" ] && [ "$git_branch" != "master" ]; then
        technical_context="${technical_context} [$git_branch]"
    fi
    
    # Append technical context to description if we have any
    if [ -n "$technical_context" ]; then
        enhanced_description="${description}${technical_context}"
    fi
    
    # Build enhanced body with system information
    local enhanced_body="$body"
    if [ -z "$enhanced_body" ] && [ "$git_status" != "clean" ]; then
        enhanced_body="System state: ${git_status}, commit: ${git_short_commit}"
        if [ -n "$generation_info" ]; then
            enhanced_body="${enhanced_body}, ${generation_info}"
        fi
    fi
    
    # Add agent signature
    local agent_sig
    agent_sig=$(get_commit_agent "$script_name")
    local timestamp
    timestamp=$(get_stardate_timestamp)
    local signature="${agent_sig} <${timestamp}>"
    
    # Build the complete enhanced message
    local enhanced_message=""
    
    # First line: type(scope): enhanced_description
    if [ -n "$scope" ]; then
        enhanced_message="${type}(${scope}): ${enhanced_description}"
    else
        enhanced_message="${type}: ${enhanced_description}"
    fi
    
    # Add body if present
    if [ -n "$enhanced_body" ]; then
        enhanced_message="${enhanced_message}

${enhanced_body}"
    fi
    
    # Add footers and signature
    enhanced_message="${enhanced_message}

${signature}"
    
    # Add any existing footers
    if [ -n "$footers" ]; then
        enhanced_message="${enhanced_message}
${footers}"
    fi
    
    # Log the enhancement for analytics
    local original_length=${#original_message}
    local enhanced_length=${#enhanced_message}
    local commit_agent=$(get_commit_agent "$script_name")
    
    # Source logging library if not already available
    if command -v log_commit_enhancement >/dev/null 2>&1; then
        log_commit_enhancement "$original_length" "$enhanced_length" "$type" "$commit_agent" "true" "$git_short_commit" "enhancement_library"
    fi
    
    echo "$enhanced_message"
}

# Validate commit message against Gigi's Commitus standards
validate_commit_message() {
    local message="$1"
    local errors=()
    
    # Check if message follows conventional commit format
    if ! echo "$message" | grep -qE '^[a-z]+(\([^)]+\))?: .+'; then
        errors+=("Message must follow conventional commit format: type(scope): description")
    fi
    
    # Check for valid type (read from Lord Gig's Standards of Commitence if available)
    local first_line
    first_line=$(echo "$message" | head -n1)
    local type
    type=$(echo "$first_line" | sed -E 's/^([a-z]+).*/\1/')
    
    # Basic type validation (extend this by parsing gigis-commitus.md)
    local valid_types="feat fix docs style refactor perf test build ci chore revert eng ops security config agent auto hook log fleet nix home host comm sitrep metrics journal"
    if ! echo "$valid_types" | grep -qw "$type"; then
        errors+=("Unknown commit type: $type. Check gigis-commitus.md for valid types.")
    fi
    
    # Check description length
    local description
    description=$(echo "$first_line" | sed -E 's/^[a-z]+(\([^)]+\))?: (.+)/\2/')
    if [ ${#description} -gt 72 ]; then
        errors+=("Description too long (${#description} chars). Keep under 72 characters.")
    fi
    
    # Return validation results
    if [ ${#errors[@]} -eq 0 ]; then
        return 0
    else
        printf '%s\n' "${errors[@]}"
        return 1
    fi
}

# Process a commit message: validate, enhance, and format
process_commit_message() {
    local original_message="$1"
    local script_name="${2:-manual}"
    local repo_dir="${3:-$(pwd)}"
    local auto_enhance="${4:-true}"
    
    # Validate the message first
    local validation_errors
    validation_errors=$(validate_commit_message "$original_message" 2>&1)
    if [ $? -ne 0 ]; then
        echo "VALIDATION ERRORS:" >&2
        echo "$validation_errors" >&2
        return 1
    fi
    
    # Enhance if requested
    if [ "$auto_enhance" = "true" ]; then
        enhance_commit_message "$original_message" "$script_name" "$repo_dir"
    else
        echo "$original_message"
    fi
}

# Batch process multiple commits (for /liven-commits command)
liven_commits() {
    local repo_dir="${1:-$(pwd)}"
    local commit_range="${2:-HEAD~5..HEAD}"
    
    cd "$repo_dir" || return 1
    
    echo "🔧 SCOTTY'S COMMIT LIVENING PROTOCOL ENGAGED"
    echo "======================================================"
    echo "Analyzing commits in range: $commit_range"
    echo ""
    
    local commits
    commits=$(git rev-list --reverse "$commit_range")
    local enhanced_count=0
    local error_count=0
    
    for commit in $commits; do
        echo "Processing commit: $(git log --oneline -n1 "$commit")"
        
        local original_message
        original_message=$(git log --format=%B -n1 "$commit")
        
        # Check if already has agent signature
        if echo "$original_message" | grep -qE "(Chief-Engineer|Captain|Auto-System):"; then
            echo "  ✓ Already enhanced, skipping"
            continue
        fi
        
        # Enhance the commit message
        local enhanced_message
        enhanced_message=$(process_commit_message "$original_message" "liven-commits" "$repo_dir")
        
        if [ $? -eq 0 ]; then
            # Update the commit message
            if git rebase --exec "git commit --amend -m \"$enhanced_message\"" "$commit^"; then
                echo "  ✓ Enhanced successfully"
                ((enhanced_count++))
            else
                echo "  ✗ Failed to update commit"
                ((error_count++))
            fi
        else
            echo "  ✗ Validation failed"
            ((error_count++))
        fi
        
        echo ""
    done
    
    echo "======================================================"
    echo "LIVENING COMPLETE: $enhanced_count enhanced, $error_count errors"
    
    return $error_count
}

# Export functions for use by hooks and scripts
export -f enhance_commit_message
export -f validate_commit_message
export -f process_commit_message
export -f liven_commits
export -f get_stardate_timestamp
export -f get_commit_agent
export -f parse_commit_message
