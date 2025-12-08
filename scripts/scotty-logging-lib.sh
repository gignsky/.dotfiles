#!/bin/bash

# =============================================================================
# SCOTTY'S ENGINEERING LOGGING LIBRARY
# =============================================================================
# Shared functions for automatic git and build state logging
# Used by git hooks, build scripts, and other automation

# Source host detection library for enhanced logging context
HOST_DETECTION_LIB_PATHS=(
    "${HOME}/.dotfiles/scripts/host-detection-lib.sh"
    "$(dirname "$0")/host-detection-lib.sh"
)

HOST_DETECTION_FOUND=false
for lib_path in "${HOST_DETECTION_LIB_PATHS[@]}"; do
    if [ -n "$lib_path" ] && [ -f "$lib_path" ]; then
        source "$lib_path"
        HOST_DETECTION_FOUND=true
        break
    fi
done

if [ "$HOST_DETECTION_FOUND" = false ]; then
    # Fallback: basic host identification if library not found
    get_host_identifier() { echo "${1:-$(hostname)}"; }
    detect_flake_target() { echo "${1:-$(hostname)}"; }
fi

# FAILSAFE LOGGING FUNCTION
# For critical operations when normal logging might fail (e.g., during clean)
failsafe_log() {
    local message="$1"
    local fallback_log="${HOME}/.dotfiles/failsafe-operations.log"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Try normal logging first
    if command -v scotty_log_event >/dev/null 2>&1; then
        scotty_log_event "system-operation" "$message" && return 0
    fi
    
    # Failsafe: Write to emergency log
    echo "[${timestamp}] FAILSAFE LOG: $message" >> "$fallback_log"
    echo "⚠️ Logged to failsafe: $message" >&2
}

# BATCHED LOGGING SYSTEM
# Accumulates log entries and commits them periodically to reduce commit noise
BATCH_LOG_DIR="${HOME}/.dotfiles/.batch-logs"
BATCH_THRESHOLD=5  # Commit after this many entries
BATCH_MAX_AGE=3600 # Commit after this many seconds (1 hour)

# Add entry to batch queue instead of immediate commit
scotty_batch_log() {
    local log_type="$1"
    local title="$2"
    local content="$3"
    
    mkdir -p "$BATCH_LOG_DIR"
    local batch_file="${BATCH_LOG_DIR}/pending-$(date '+%Y%m%d').batch"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Add to batch file
    cat >> "$batch_file" << EOF
---BATCH-ENTRY-START---
TYPE: $log_type
TIMESTAMP: $timestamp
TITLE: $title
CONTENT: $content
---BATCH-ENTRY-END---
EOF
    
    # Check if we should commit batch
    _check_batch_commit_needed
}

# Check if batch should be committed based on size or age
_check_batch_commit_needed() {
    local batch_files=($(find "$BATCH_LOG_DIR" -name "*.batch" 2>/dev/null))
    [ ${#batch_files[@]} -eq 0 ] && return 0
    
    local total_entries=0
    local oldest_file=""
    local oldest_time=999999999
    
    for batch_file in "${batch_files[@]}"; do
        local entries=$(grep -c "^---BATCH-ENTRY-START---" "$batch_file" 2>/dev/null || echo 0)
        total_entries=$((total_entries + entries))
        
        local file_time=$(stat -c %Y "$batch_file" 2>/dev/null || stat -f %m "$batch_file" 2>/dev/null || echo 0)
        if [ "$file_time" -lt "$oldest_time" ]; then
            oldest_time=$file_time
            oldest_file="$batch_file"
        fi
    done
    
    local current_time=$(date +%s)
    local age=$((current_time - oldest_time))
    
    # Commit if threshold reached or max age exceeded
    if [ "$total_entries" -ge "$BATCH_THRESHOLD" ] || [ "$age" -ge "$BATCH_MAX_AGE" ]; then
        _commit_batch_logs
    fi
}

# Commit all pending batch logs
_commit_batch_logs() {
    local batch_files=($(find "$BATCH_LOG_DIR" -name "*.batch" 2>/dev/null))
    [ ${#batch_files[@]} -eq 0 ] && return 0
    
    echo "📊 Processing batched engineering logs..."
    
    for batch_file in "${batch_files[@]}"; do
        _process_batch_file "$batch_file"
    done
    
    # Clean up batch files
    rm -f "${batch_files[@]}"
    
    # Commit the logs
    cd "${HOME}/.dotfiles"
    git add scottys-journal/ 2>/dev/null
    git commit -m "📊 Scotty: Batch commit engineering logs ($(date '+%H:%M'))" 2>/dev/null
    
    echo "✅ Batched logs committed successfully"
}

# Process individual batch file into proper logs
_process_batch_file() {
    local batch_file="$1"
    local current_entry=""
    local entry_type=""
    local entry_timestamp=""
    local entry_title=""
    local entry_content=""
    local in_entry=false
    
    while IFS= read -r line; do
        case "$line" in
            "---BATCH-ENTRY-START---")
                in_entry=true
                entry_type=""
                entry_timestamp=""
                entry_title=""
                entry_content=""
                ;;
            "---BATCH-ENTRY-END---")
                if [ "$in_entry" = true ]; then
                    # Process this entry using existing logging functions
                    if [ -n "$entry_type" ] && [ -n "$entry_title" ]; then
                        # Use the original logging function but bypass batching
                        _direct_log_entry "$entry_type" "$entry_title" "$entry_content" "$entry_timestamp"
                    fi
                fi
                in_entry=false
                ;;
            TYPE:*)
                entry_type="${line#TYPE: }"
                ;;
            TIMESTAMP:*)
                entry_timestamp="${line#TIMESTAMP: }"
                ;;
            TITLE:*)
                entry_title="${line#TITLE: }"
                ;;
            CONTENT:*)
                entry_content="${line#CONTENT: }"
                ;;
        esac
    done < "$batch_file"
}

# Direct logging bypass for batch processing
_direct_log_entry() {
    local log_type="$1"
    local title="$2"
    local content="$3" 
    local custom_timestamp="$4"
    
    # Use custom timestamp if provided, otherwise current time
    local timestamp="${custom_timestamp:-$(date '+%Y-%m-%d %H:%M:%S')}"
    
    # Call the original logging function with bypass flag
    BYPASS_BATCH=1 scotty_log_event "$log_type" "$title" "$content"
}

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

# Log commit enhancement data for analytics
log_commit_enhancement() {
    local original_length="$1"
    local enhanced_length="$2"
    local commit_type="$3"
    local agent="$4"
    local validation_passed="$5"
    local git_commit="$6"
    local enhancement_method="${7:-automatic}"
    
    ensure_journal_dirs
    
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local host
    host=$(hostname)
    
    local csv_file="${METRICS_DIR}/commit-enhancements.csv"
    
    # Create header if file doesn't exist
    if [ ! -f "$csv_file" ]; then
        echo "date,host,git_commit,commit_type,original_length,enhanced_length,agent,validation_passed,enhancement_method,technical_context_added" > "$csv_file"
    fi
    
    # Calculate if technical context was added
    local tech_context_added=$((enhanced_length > original_length ? 1 : 0))
    
    # Append the data
    echo "${timestamp},${host},${git_commit},${commit_type},${original_length},${enhanced_length},${agent},${validation_passed},${enhancement_method},${tech_context_added}" >> "$csv_file"
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
    
    # Check if batching is bypassed (for internal processing)
    if [ "$BYPASS_BATCH" = "1" ]; then
        unset BYPASS_BATCH
        _original_scotty_log_event "$event_type" "$@"
        return
    fi
    
    # Use batching for regular operations
    case "$event_type" in
        "git-commit")
            local message="$1"
            scotty_batch_log "git-operation" "Git Commit" "Committed changes: $message"
            ;;
        "build-complete"|"system-operation")
            # High-value events - log immediately
            _original_scotty_log_event "$event_type" "$@"
            ;;
        *)
            # Default: batch low-value events
            scotty_batch_log "$event_type" "Event: $event_type" "$*"
            ;;
    esac
}

# Original logging function for immediate processing
_original_scotty_log_event() {
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
            # Extract host from operation string and enhance it
            local host_part=$(echo "$operation" | sed 's/.*-\([^-]*\)$/\1/')
            local enhanced_host=$(get_host_identifier "$host_part")
            local enhanced_operation=$(echo "$operation" | sed "s/-${host_part}$/-${enhanced_host}/")
            create_narrative_entry "BUILD START" "Starting $enhanced_operation" "note"
            ;;
        "build-complete")
            local operation="$1"
            local duration="$2"
            local success="$3"
            local generation="$4"
            # Extract host from operation string and enhance it
            local host_part=$(echo "$operation" | sed 's/.*-\([^-]*\)$/\1/')
            local enhanced_host=$(get_host_identifier "$host_part")
            local enhanced_operation=$(echo "$operation" | sed "s/-${host_part}$/-${enhanced_host}/")
            log_build_performance "$enhanced_operation" "$duration" "$success" "" "Automated build logging" "$generation"
            create_narrative_entry "BUILD COMPLETE" "$enhanced_operation completed in ${duration}s (success: $success, generation: $generation)" "report"
            ;;
        "build-error")
            local operation="$1"
            local error="$2"
            # Extract host from operation string and enhance it
            local host_part=$(echo "$operation" | sed 's/.*-\([^-]*\)$/\1/')
            local enhanced_host=$(get_host_identifier "$host_part")
            local enhanced_operation=$(echo "$operation" | sed "s/-${host_part}$/-${enhanced_host}/")
            log_error "build-failure" "$error" "Manual intervention required" "0" "false"
            create_narrative_entry "BUILD ERROR" "$enhanced_operation failed: $error" "report"
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
export -f log_commit_enhancement
export -f get_git_state
export -f get_home_manager_generation
export -f display_captain_report
