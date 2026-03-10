#!/usr/bin/env bash

# Parse command-line arguments
VERBOSE=false
TEST_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -t|--test)
            TEST_MODE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [-v|--verbose] [-t|--test]"
            echo "  -v, --verbose    Show full output with --show-trace"
            echo "  -t, --test       Use 'build' instead of 'switch' to test without activating"
            exit 1
            ;;
    esac
done

# Source host detection library for intelligent WSL handling
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
    # Fallback: basic host detection if library not found
    detect_flake_target() {
        if [ -n "$1" ]; then
            echo "$1"
        elif [ "$(hostname)" = "nixos" ]; then
            echo "wsl"
        else
            echo "$(hostname)"
        fi
    }
    get_host_identifier() { echo "$1"; }
fi

# Enhanced host detection with intelligent WSL mapping  
# Use auto-detected hostname, don't treat arguments as hostname
export HOST=$(detect_flake_target)
export HOST_IDENTIFIER=$(get_host_identifier "$HOST")

# Source Scotty's logging library for automatic build logging
# Try multiple locations for the logging library
LOGGING_LIB_PATHS=(
  "${SCOTTY_LOGGING_LIB_PATH:-}"
  "${HOME}/.dotfiles/scripts/scotty-logging-lib.sh"
  "$(dirname "$0")/scotty-logging-lib.sh"
)

LOGGING_LIB_FOUND=false
for lib_path in "${LOGGING_LIB_PATHS[@]}"; do
  if [ -n "$lib_path" ] && [ -f "$lib_path" ]; then
    source "$lib_path"
    LOGGING_LIB_FOUND=true
    break
  fi
done

if [ "$LOGGING_LIB_FOUND" = false ]; then
  # Fallback: define basic logging functions if library is not found
  scotty_log_event() { echo "[$1] $*" >&2; }
  log_build_performance() {
    local operation="$1"
    local duration_seconds="$2"
    local success="$3"
    local error_type="$4"
    local notes="$5"
    local generation_number="${6:-unknown}"

    local annex_dir="${HOME}/local_repos/annex"
    local metrics_dir="${annex_dir}/fleet/operations/metrics"
    mkdir -p "$metrics_dir"

    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local host
    host=$(hostname)

    # Get git state
    local git_commit
    git_commit=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
    local git_branch
    git_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
    local git_status="clean"
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
      local modified_count
      modified_count=$(git status --porcelain | wc -l)
      git_status="${modified_count}_modified"
    fi
    local flake_lock_hash="none"
    if [ -f "flake.lock" ]; then
      flake_lock_hash=$(sha256sum flake.lock | cut -d' ' -f1)
    fi

    local csv_file="${metrics_dir}/build-performance.csv"

    # Create header if file doesn't exist
    if [ ! -f "$csv_file" ]; then
      echo "date,host,operation,duration_seconds,success,error_type,git_commit,git_branch,git_status,flake_lock_hash,generation_number,notes" >"$csv_file"
    fi

    # Append the data
    echo "${timestamp},${host},${operation},${duration_seconds},${success},${error_type},${git_commit},${git_branch},${git_status},${flake_lock_hash},${generation_number},${notes}" >>"$csv_file"
  }
fi

# Pre-commit checks with auto-fix and validation
echo "🔍 Running pre-commit checks..."
USE_NO_VERIFY=false

# Run pre-commit checks (first pass - may auto-fix)
if ! nix develop -c pre-commit run --all-files >/dev/null 2>&1; then
  echo "⚠️  Pre-commit checks failed, attempting auto-fixes..."
  
  # Run second time to catch auto-fixes
  if ! nix develop -c pre-commit run --all-files >/dev/null 2>&1; then
    echo "❌ Pre-commit checks have unfixable errors"
    echo ""
    echo "🔧 Running flake validation to check Nix syntax..."
    
    # Capture flake check output, show only errors
    flake_check_output=$(mktemp)
    if nix flake check --keep-going 2>&1 | tee "$flake_check_output" | grep -i "error" || grep -i "error" "$flake_check_output"; then
      echo ""
      echo "❌ Flake validation FAILED"
      echo "Please fix the Nix syntax errors above before rebuilding"
      rm "$flake_check_output"
      exit 1
    else
      echo "✅ Flake validation PASSED"
      rm "$flake_check_output"
      echo ""
      echo "Pre-commit checks failed but flake validation passed."
      echo "This suggests non-Nix formatting/linting issues."
      echo ""
      
      # Interactive prompt for non-interactive-safe execution
      if [ -t 0 ] && [ -t 1 ]; then
        read -p "Continue with rebuild and commit with --no-verify? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
          echo "Rebuild cancelled. Please fix pre-commit issues first."
          exit 1
        fi
        USE_NO_VERIFY=true
        echo "⚠️  Proceeding with --no-verify flag..."
      else
        echo "❌ Non-interactive terminal - cannot prompt for override"
        echo "Please fix pre-commit issues or run interactively"
        exit 1
      fi
    fi
  else
    echo "✅ Pre-commit auto-fixes applied successfully"
  fi
else
  echo "✅ Pre-commit checks passed"
fi

# Stage any auto-fixed files
git add -u 2>/dev/null || true

set -e
pushd . || exit

# Log build start
start_time=$(date +%s)

# Capture previous generation for comparison
previous_gen=$(home-manager generations 2>/dev/null | head -n 1 | grep -o 'id [0-9]*' | grep -o '[0-9]*' || echo "0")

# Find the last home-manager rebuild commit for this host
echo "=== ANALYZING CONFIGURATION CHANGES SINCE LAST REBUILD ==="
last_rebuild_commit=$(git log --oneline --grep="gig@${HOST}:" -1 --format="%H" 2>/dev/null || echo "")

if [ -n "$last_rebuild_commit" ]; then
  echo "Last rebuild commit for ${HOST_IDENTIFIER}: ${last_rebuild_commit}"
  config_files_changed=$(git diff --name-only "${last_rebuild_commit}..HEAD" | grep -E '\.(nix|conf|toml|yaml|yml)$' || echo "")
  if [ -n "$config_files_changed" ]; then
    echo "Configuration files changed since last rebuild:"
    echo "$config_files_changed"
    # Capture detailed diff for Scotty (limited to avoid huge output)
    detailed_diff=$(git diff "${last_rebuild_commit}..HEAD" -- "*.nix" "*.conf" "*.toml" "*.yaml" "*.yml" | head -200)
  else
    config_files_changed="No configuration files changed"
    detailed_diff="No configuration changes detected"
  fi
else
  echo "No previous rebuild found for ${HOST_IDENTIFIER} - this appears to be the first rebuild"
  config_files_changed="First rebuild for this host"
  detailed_diff="Initial configuration deployment for ${HOST_IDENTIFIER}"
fi

git diff -U0 ./*glob*.nix

# Determine operation and build command
if [ "$TEST_MODE" = true ]; then
  OPERATION="build"
  echo "Home-Manager Test Building ${HOST_IDENTIFIER}..."
else
  OPERATION="switch"
  echo "Home-Manager Rebuilding ${HOST_IDENTIFIER}..."
fi

# Capture build success/failure and output
output_file=$(mktemp)
error_log_file=$(mktemp)

# Build the command arguments as array for proper execution
HM_ARGS=("$OPERATION")
if [ "$OPERATION" = "switch" ]; then
  HM_ARGS+=("-b" "backup")
fi
HM_ARGS+=("--flake" ".#gig@$HOST")
if [ "$VERBOSE" = true ]; then
  HM_ARGS+=("--show-trace")
fi

# Execute home-manager with proper output capture
set -o pipefail
if [ "$VERBOSE" = true ]; then
  # Verbose mode: show all output
  home-manager "${HM_ARGS[@]}" 2>&1 | tee "$output_file"
  BUILD_SUCCESS=${PIPESTATUS[0]}
else
  # Normal mode: capture output but show errors if build fails
  if home-manager "${HM_ARGS[@]}" > "$output_file" 2>&1; then
    BUILD_SUCCESS=0
  else
    BUILD_SUCCESS=$?
  fi
fi

if [ $BUILD_SUCCESS -eq 0 ]; then
  # Get the generation number after successful build
  if [ "$TEST_MODE" = true ]; then
    generation_number="test-build"
    gen="test build (no generation created)"
  else
    gen=$(home-manager generations 2>/dev/null | head -n 1)
    generation_number=$(echo "$gen" | grep -o 'id [0-9]*' | grep -o '[0-9]*' || echo "unknown")
  fi

  # Calculate build duration
  end_time=$(date +%s)
  duration=$((end_time - start_time))

  # Log successful build to CSV  
  log_build_performance "home-manager-rebuild-${HOST_IDENTIFIER}" "$duration" "true" "" "Automated home-manager rebuild with Scotty engineering logs" "$generation_number"

  # Automatic Scotty logging disabled - use 'just log-commit' or invoke Scotty manually if needed
  # echo "=== CALLING SCOTTY FOR DETAILED ENGINEERING LOG ==="
  # if command -v opencode >/dev/null 2>&1; then
  #   opencode run --agent scotty "Scotty, document this successful home-manager rebuild for ${HOST_IDENTIFIER}: Generation ${previous_gen} → ${generation_number}, build duration ${duration} seconds. Configuration changes since last rebuild: ${config_files_changed}. Files changed: ${detailed_diff}" || echo "Scotty logging failed, continuing..."
  # else
  #   echo "OpenCode not available - skipping detailed Scotty log"
  # fi

  # Commit with generation info
  # Create enhanced commit message using Scotty's enhancement system
  export AUTOMATED_COMMIT=true
  if [ -f "$(dirname "$0")/commit-enhance-lib.sh" ]; then
    source "$(dirname "$0")/commit-enhance-lib.sh"
    enhanced_msg=$(enhance_commit_message "auto(home): rebuild $HOST_IDENTIFIER generation $gen" "home-manager-flake-rebuild.sh")
    if [ "$USE_NO_VERIFY" = true ]; then
      git commit -a --allow-empty --no-verify -m "$enhanced_msg" || true
    else
      git commit -a --allow-empty -m "$enhanced_msg" || true
    fi
  else
    # Fallback to basic message if enhancement library not available
    if [ "$USE_NO_VERIFY" = true ]; then
      git commit -a --allow-empty --no-verify -m "gig@$HOST_IDENTIFIER: $gen" || true
    else
      git commit -a --allow-empty -m "gig@$HOST_IDENTIFIER: $gen" || true
    fi
  fi

  echo "✅ Home Manager rebuild successful! Generation: $generation_number (${duration}s) for ${HOST_IDENTIFIER}"
  echo "📝 Detailed engineering log created by Scotty"
  
  # Clean up temp files on success
  rm -f "$output_file" "$error_log_file"
else
  end_time=$(date +%s)
  duration=$((end_time - start_time))

  echo ""
  echo "❌ Home Manager rebuild failed for ${HOST_IDENTIFIER}!"
  echo ""
  echo "=== 🔍 EXTRACTING ERROR MESSAGES FROM BUILD LOG ==="
  echo ""
  
  # Extract lines containing 'error:' (Nix evaluation errors)
  grep -i "error:" "$output_file" > "$error_log_file" 2>/dev/null || true
  
  # Also look for 'attribute.*missing' patterns (common Nix error)
  grep -i "attribute.*missing" "$output_file" >> "$error_log_file" 2>/dev/null || true
  
  # Look for 'undefined variable' errors
  grep -i "undefined variable" "$output_file" >> "$error_log_file" 2>/dev/null || true
  
  # Look for 'syntax error' patterns
  grep -i "syntax error" "$output_file" >> "$error_log_file" 2>/dev/null || true
  
  # Look for 'builder for.*failed' (build-time errors)
  grep -i "builder for.*failed" "$output_file" >> "$error_log_file" 2>/dev/null || true
  
  # Look for home-manager specific errors
  grep -i "collision between" "$output_file" >> "$error_log_file" 2>/dev/null || true
  
  # If we found error lines, show them prominently
  if [ -s "$error_log_file" ]; then
    echo "🚨 KEY ERROR MESSAGES:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    cat "$error_log_file" | sed 's/^/  /'
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Show detailed context around the LAST error (usually most specific)
    # Get the line number of the last error occurrence
    last_error_line=$(grep -n "error:" "$output_file" | tail -1 | cut -d: -f1)
    if [ -n "$last_error_line" ]; then
      echo "📍 DETAILED ERROR CONTEXT (most specific error with 20 lines of context):"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      # Show 2 lines before and 20 lines after the last error
      tail -n +"$((last_error_line - 2))" "$output_file" | head -n 23 | sed 's/^/  /'
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""
    fi
    
    error_info=$(cat "$error_log_file" | head -n 3 | tr '\n' ' ')
  else
    echo "⚠️  No obvious error patterns found. Showing last 15 lines of output:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    tail -n 15 "$output_file" | sed 's/^/  /'
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    error_info="Home-manager rebuild failed - see output above"
  fi
  
  echo ""
  echo "💡 To see full build output, run with --verbose flag or check: $output_file"
  echo ""

  # Log failed build to CSV
  log_build_performance "home-manager-rebuild-${HOST_IDENTIFIER}" "$duration" "false" "home-manager-switch-failed" "Build failed during switch operation" "unknown"

  # Automatic Scotty logging disabled - use 'just log-commit' or invoke Scotty manually if needed
  # echo "=== CALLING SCOTTY FOR FAILURE ANALYSIS ==="
  # if command -v opencode >/dev/null 2>&1; then
  #   opencode run --agent scotty "Scotty, document this FAILED home-manager rebuild for ${HOST_IDENTIFIER}: Build duration ${duration} seconds, previous generation ${previous_gen}. Configuration changes attempted: ${config_files_changed}. Analyze what went wrong and provide troubleshooting recommendations." || echo "Scotty logging failed"
  # else
  #   echo "OpenCode not available - skipping detailed Scotty failure log"
  # fi

  # Clean up error log but keep full output for debugging
  rm "$error_log_file"
  echo "📋 Full build log saved to: $output_file"
  echo "   (This file will be cleaned up on next successful build)"
  exit 1
fi

popd || exit
