#!/bin/bash

# =============================================================================
# SCOTTY'S ENGINEERING LOGGING LIBRARY
# =============================================================================
# Shared functions for automatic git and build state logging
# Used by git hooks, build scripts, and other automation

# Configuration - determine the correct dotfiles path
if [ -d "${PWD}/scottys-journal" ]; then
    # We're in the dotfiles repo root
    JOURNAL_DIR="${PWD}/scottys-journal"
elif [ -d "${HOME}/.dotfiles/scottys-journal" ]; then
    # Use the standard dotfiles location
    JOURNAL_DIR="${HOME}/.dotfiles/scottys-journal"
else
    # Default fallback
    JOURNAL_DIR="${HOME}/.dotfiles/scottys-journal"
fi
LOGS_DIR="${JOURNAL_DIR}/logs"
METRICS_DIR="${JOURNAL_DIR}/metrics"

# Ensure journal directories exist
ensure_journal_dirs() {
    mkdir -p "$LOGS_DIR"
    mkdir -p "$METRICS_DIR"
}

# Get current git state information
get_git_state() {
    local repo_dir="${1:-$(pwd)}"
    cd "$repo_dir" || return 1
    
    local git_commit
    git_commit=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
    local git_branch
    git_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
    local git_short_commit
    git_short_commit=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    
    # Check git status
    local git_status="clean"
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        local modified_count
        modified_count=$(git status --porcelain | wc -l)
        git_status="${modified_count}_modified"
    fi
    
    # Get flake.lock hash if it exists
    local flake_lock_hash="none"
    if [ -f "flake.lock" ]; then
        flake_lock_hash=$(sha256sum flake.lock | cut -d' ' -f1)
    fi
    
    echo "${git_commit}|${git_branch}|${git_status}|${flake_lock_hash}|${git_short_commit}"
}

# Log build performance data
log_build_performance() {
    local operation="$1"
    local duration_seconds="$2"  
    local success="$3"
    local error_type="$4"
    local notes="$5"
    local generation_number="${6:-unknown}"
    
    ensure_journal_dirs
    
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local host
    host=$(hostname)
    local git_info
    git_info=$(get_git_state "$(pwd)")
    
    IFS='|' read -r git_commit git_branch git_status flake_lock_hash git_short_commit <<< "$git_info"
    
    local csv_file="${METRICS_DIR}/build-performance.csv"
    
    # Create header if file doesn't exist
    if [ ! -f "$csv_file" ]; then
        echo "date,host,operation,duration_seconds,success,error_type,git_commit,git_branch,git_status,flake_lock_hash,generation_number,notes" > "$csv_file"
    fi
    
    # Append the data
    echo "${timestamp},${host},${operation},${duration_seconds},${success},${error_type},${git_commit},${git_branch},${git_status},${flake_lock_hash},${generation_number},${notes}" >> "$csv_file"
}

# Log git operations
log_git_operation() {
    local operation="$1"
    local details="$2"
    
    ensure_journal_dirs
    
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local host
    host=$(hostname)
    local git_info
    git_info=$(get_git_state "$(pwd)")
    
    IFS='|' read -r git_commit git_branch git_status flake_lock_hash git_short_commit <<< "$git_info"
    
    local csv_file="${METRICS_DIR}/git-operations.csv"
    
    # Create header if file doesn't exist
    if [ ! -f "$csv_file" ]; then
        echo "date,host,operation,git_commit,git_branch,git_status,flake_lock_hash,details" > "$csv_file"
    fi
    
    # Append the data
    echo "${timestamp},${host},${operation},${git_commit},${git_branch},${git_status},${flake_lock_hash},${details}" >> "$csv_file"
}

# Log error information
log_error() {
    local error_type="$1"
    local error_message="$2"
    local solution_applied="$3"
    local resolution_time_minutes="$4"
    local prevented_future="${5:-false}"
    
    ensure_journal_dirs
    
    local timestamp
    timestamp=$(date '+%Y-%m-%d')
    local host
    host=$(hostname)
    
    local csv_file="${METRICS_DIR}/error-tracking.csv"
    
    # Create header if file doesn't exist
    if [ ! -f "$csv_file" ]; then
        echo "date,host,error_type,error_message,solution_applied,resolution_time_minutes,prevented_future" > "$csv_file"
    fi
    
    # Append the data (escape commas in messages)
    local escaped_message="${error_message//,/;}"
    local escaped_solution="${solution_applied//,/;}"
    echo "${timestamp},${host},${error_type},${escaped_message},${escaped_solution},${resolution_time_minutes},${prevented_future}" >> "$csv_file"
}

# Get current home-manager generation number
get_home_manager_generation() {
    local profile_path="${HOME}/.local/state/nix/profiles/home-manager"
    if [ -L "$profile_path" ]; then
        readlink "$profile_path" | sed -n 's/.*-\([0-9]\+\)-link/\1/p'
    else
        echo "unknown"
    fi
}

# Create a narrative log entry with optional classification for Captain's attention
create_narrative_entry() {
    local title="$1"
    local content="$2"
    local log_type="${3:-note}"  # Default to 'note', can be 'report' for Captain's attention
    
    ensure_journal_dirs
    
    local date
    date=$(date '+%Y-%m-%d')
    local stardate
    stardate=$(date '+%Y.%m.%d')
    local log_file="${LOGS_DIR}/${date}-automated.log"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Create or append to log file
    if [ ! -f "$log_file" ]; then
        cat << EOF > "$log_file"
================================================================================
CHIEF ENGINEER'S LOG - STARDATE ${stardate} (AUTOMATED)
================================================================================

EOF
    fi
    
    # Add classification marker for reports
    local entry_header="[${timestamp}] ${title}"
    if [ "$log_type" = "report" ]; then
        entry_header="[${timestamp}] ★ CAPTAIN'S REPORT ★ ${title}"
    fi
    
    cat << EOF >> "$log_file"
${entry_header}
${content}

EOF

    # Auto-display reports using bat if available and stdout is a terminal
    if [ "$log_type" = "report" ] && [ -t 1 ]; then
        display_captain_report "$log_file" "$entry_header"
    fi
}

# Display a Captain's report using bat or fallback to cat
display_captain_report() {
    local log_file="$1"
    local entry_header="$2"
    
    echo ""
    echo "════════════════════════════════════════════════════════════════════"
    echo "🚨 NEW ENGINEERING REPORT FOR CAPTAIN'S REVIEW 🚨"
    echo "════════════════════════════════════════════════════════════════════"
    
    # Try to use bat for syntax highlighting and paging
    if command -v bat >/dev/null 2>&1; then
        # Extract just the latest entry for display
        local temp_file=$(mktemp)
        local in_current_entry=false
        local entry_found=false
        
        while IFS= read -r line; do
            if [[ "$line" == *"$entry_header"* ]]; then
                in_current_entry=true
                entry_found=true
                echo "$line" >> "$temp_file"
            elif [ "$in_current_entry" = true ] && [[ "$line" =~ ^\[.*\][[:space:]]*★?[[:space:]]*(CAPTAIN\'S[[:space:]]+REPORT[[:space:]]+)?★?[[:space:]]*.* ]]; then
                # Found start of next entry, stop
                break
            elif [ "$in_current_entry" = true ]; then
                echo "$line" >> "$temp_file"
            fi
        done < "$log_file"
        
        if [ "$entry_found" = true ]; then
            bat --style=numbers,changes --theme="Monokai Extended" --language=markdown "$temp_file" 2>/dev/null || cat "$temp_file"
        else
            echo "Error: Could not extract report content"
        fi
        
        rm -f "$temp_file"
    else
        # Fallback to cat with basic formatting
        echo "Entry: $entry_header"
        echo "────────────────────────────────────────────────────────────────────"
        tail -n 20 "$log_file" | head -n 15
    fi
    
    echo "════════════════════════════════════════════════════════════════════"
    echo ""
}

# Function to be called from git hooks or build scripts
scotty_log_event() {
    local event_type="$1"
    shift
    
    case "$event_type" in
        "git-commit")
            local message="$1"
            log_git_operation "commit" "$message"
            create_narrative_entry "GIT COMMIT" "Committed changes: $message" "note"
            ;;
        "git-push-prep")
            local details="$1"
            log_git_operation "push-prep" "$details"
            create_narrative_entry "GIT PUSH PREPARATION" "$details"
            ;;
        "build-start")
            local operation="$1"
            create_narrative_entry "BUILD START" "Starting $operation" "note"
            ;;
        "build-complete")
            local operation="$1"
            local duration="$2"
            local success="$3"
            local generation="$4"
            log_build_performance "$operation" "$duration" "$success" "" "Automated build logging" "$generation"
            create_narrative_entry "BUILD COMPLETE" "$operation completed in ${duration}s (success: $success, generation: $generation)" "report"
            ;;
        "build-error")
            local operation="$1"
            local error="$2"
            log_error "build-failure" "$error" "Manual intervention required" "0" "false"
            create_narrative_entry "BUILD ERROR" "$operation failed: $error" "report"
            ;;
        *)
            create_narrative_entry "UNKNOWN EVENT" "$event_type: $*" "note"
            ;;
    esac
}

# Enhanced function for Scotty agent to create classified logs
scotty_create_log() {
    local title="$1"
    local content="$2"
    local log_type="${3:-note}"  # 'note' or 'report'
    
    create_narrative_entry "$title" "$content" "$log_type"
}

# Export functions for use by other scripts
export -f scotty_log_event
export -f scotty_create_log
export -f log_build_performance
export -f log_git_operation
export -f log_error
export -f get_git_state
export -f get_home_manager_generation
export -f display_captain_report
