#!/usr/bin/env bash

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

# Source Scotty's logging library for automatic build logging
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
    # echo "DEBUG: Using fallback logging functions"
    scotty_log_event() { echo "[$1] $*" >&2; }
    log_build_performance() { echo "Build: $1 took $2 seconds (success: $3)" >&2; }
else
    # echo "DEBUG: Scotty logging library loaded from: ${lib_path}"
    true
fi

# Enhanced host detection with intelligent WSL mapping
# Use auto-detected hostname, don't treat arguments as hostname
export HOST=$(detect_flake_target)
export HOST_IDENTIFIER=$(get_host_identifier "$HOST")

# Store all arguments for passing to nixos-rebuild
NIXOS_REBUILD_ARGS="$*"
if [ -z "$NIXOS_REBUILD_ARGS" ]; then
    NIXOS_REBUILD_ARGS="switch"
fi

authenticate_sudo() {
    echo "🔐 NixOS rebuild requires sudo access for ${HOST_IDENTIFIER}..."
    if ! sudo -n true 2>/dev/null; then
        if [ -t 0 ] && [ -t 1 ]; then
            # Interactive terminal available
            echo "Please enter your password to authenticate sudo:"
            sudo true || {
                echo "❌ Sudo authentication failed. Exiting."
                exit 1
            }
            echo "✅ Sudo authentication successful for ${HOST_IDENTIFIER}."
        else
            # No interactive terminal - provide helpful guidance
            echo ""
            echo "❌ No interactive terminal available for sudo authentication."
            echo ""
            echo "To fix this, please choose one of the following options:"
            echo "  1. Run this command from an interactive terminal"
            echo "  2. First authenticate sudo manually: sudo -v"
                echo "  3. Run the rebuild command directly: sudo nixos-rebuild switch --flake .#${HOST}"
            echo ""
            exit 1
        fi
    else
        echo "✅ Sudo already authenticated for ${HOST_IDENTIFIER}."
    fi
}

authenticate_sudo

# echo "DEBUG: Authentication completed successfully"

# Pre-commit checks with auto-fix and validation
echo "🔍 Running pre-commit checks..."
USE_NO_VERIFY=false

# Run pre-commit checks (first pass - may auto-fix)
if ! nix develop -c pre-commit run --all-files 2>&1; then
  echo "⚠️  Pre-commit checks failed, attempting auto-fixes..."
  
  # Run second time to catch auto-fixes
  if ! nix develop -c pre-commit run --all-files 2>&1; then
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

# echo "DEBUG: About to set -e"
set -e
# echo "DEBUG: About to pushd"
pushd . || exit
# echo "DEBUG: pushd completed successfully"

# Log build start with enhanced host information (WSL uses direct logging)
start_time=$(date +%s)
# echo "DEBUG: About to log build start for ${HOST_IDENTIFIER}"

# Debug: Check if scotty_log_event function is available
if command -v scotty_log_event >/dev/null 2>&1; then
    # echo "DEBUG: scotty_log_event function is available"
    true
elif type scotty_log_event >/dev/null 2>&1; then
    # echo "DEBUG: scotty_log_event is defined as a function"  
    true
else
    echo "ERROR: scotty_log_event not found!"
    exit 1
fi

if [ "$(hostname)" = "nixos" ]; then
    # WSL: Use direct logging to avoid batch processing hangs
    # echo "DEBUG: Using WSL logging path"
    BYPASS_BATCH=1 scotty_log_event "build-start" "nixos-rebuild-${HOST_IDENTIFIER}" || {
        # echo "DEBUG: WSL logging failed, using fallback"
        echo "[build-start] nixos-rebuild-${HOST_IDENTIFIER}" >&2
    }
else
    # Native Linux: Use normal batched logging with fallback
    # echo "DEBUG: Using normal logging path"
    scotty_log_event "build-start" "nixos-rebuild-${HOST_IDENTIFIER}" || {
        # echo "DEBUG: Normal logging failed, using fallback"
        echo "[build-start] nixos-rebuild-${HOST_IDENTIFIER}" >&2
    }
fi
# echo "DEBUG: Logging completed successfully"

# Capture previous generation for comparison
previous_gen=$(nixos-rebuild list-generations 2>/dev/null | grep -E "(current|True)" | grep -o '[0-9]*' | head -n 1 || echo "0")

# Find the last nixos-rebuild commit for this host
echo "=== ANALYZING CONFIGURATION CHANGES SINCE LAST REBUILD ==="
last_rebuild_commit=$(git log --oneline --grep="${HOST}:" -1 --format="%H" 2>/dev/null || echo "")

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
echo "NixOS Rebuilding ${HOST_IDENTIFIER}..."

# Capture build output and success/failure with robust exit code handling
output_file=$(mktemp)

# Use pipefail to ensure we capture the exit code of nixos-rebuild, not tee
set -o pipefail

# Run nixos-rebuild and capture both output and exit code properly
echo "Starting nixos-rebuild switch for ${HOST_IDENTIFIER}..."
if sudo nixos-rebuild switch --flake .#"$HOST" 2>&1 | tee "$output_file"; then
  nixos_rebuild_exit_code=${PIPESTATUS[0]}
else
  nixos_rebuild_exit_code=${PIPESTATUS[0]}
fi

# Double-check the actual exit code from nixos-rebuild (not tee)
if [ "$nixos_rebuild_exit_code" -eq 0 ]; then
  build_success="true"
  
  # Extract generation number from nixos-rebuild output or list-generations
  gen=$(nixos-rebuild list-generations 2>/dev/null | grep current || echo "unknown generation")
  generation_number=$(echo "$gen" | grep -o '[0-9]*' | head -n 1 || echo "unknown")
  
  # Calculate build duration
  end_time=$(date +%s)
  duration=$((end_time - start_time))
  
  # Log successful build with enhanced host information (WSL uses direct logging)
  if [ "$(hostname)" = "nixos" ]; then
      # WSL: Use direct logging to avoid batch processing hangs
      BYPASS_BATCH=1 scotty_log_event "build-complete" "nixos-rebuild-${HOST_IDENTIFIER}" "$duration" "$build_success" "$generation_number"
  else
      # Native Linux: Use normal batched logging
      scotty_log_event "build-complete" "nixos-rebuild-${HOST_IDENTIFIER}" "$duration" "$build_success" "$generation_number"
  fi
  
  # Automatic Scotty logging disabled - use 'just log-commit' or invoke Scotty manually if needed
  # echo "=== CALLING SCOTTY FOR DETAILED ENGINEERING LOG ==="
  # if command -v opencode >/dev/null 2>&1; then
  #   opencode run --agent scotty "Scotty, document this successful nixos-rebuild for ${HOST_IDENTIFIER}: Generation ${previous_gen} → ${generation_number}, build duration ${duration} seconds. Configuration changes since last rebuild: ${config_files_changed}. Files changed: ${detailed_diff}" || echo "Scotty logging failed, continuing..."
  # else
  #   echo "OpenCode not available - skipping detailed Scotty log"
  # fi
  
  # Commit with enhanced generation info
  export AUTOMATED_COMMIT=true
  if [ -f "$(dirname "$0")/commit-enhance-lib.sh" ]; then
    source "$(dirname "$0")/commit-enhance-lib.sh"
    enhanced_msg=$(enhance_commit_message "auto(system): rebuild $HOST_IDENTIFIER generation $gen" "system-flake-rebuild.sh")
    if [ "$USE_NO_VERIFY" = true ]; then
      git commit -a --allow-empty --no-verify -m "$enhanced_msg" || true
    else
      git commit -a --allow-empty -m "$enhanced_msg" || true
    fi
  else
    # Fallback to basic message if enhancement library not available
    if [ "$USE_NO_VERIFY" = true ]; then
      git commit -a --allow-empty --no-verify -m "$HOST_IDENTIFIER: $gen" || true
    else
      git commit -a --allow-empty -m "$HOST_IDENTIFIER: $gen" || true
    fi
  fi
else
  echo "nixos-rebuild failed with exit code: $nixos_rebuild_exit_code"
  build_success="false"
  end_time=$(date +%s)
  duration=$((end_time - start_time))
  
  # Extract error information from output
  error_info=$(tail -n 5 "$output_file" | tr '\n' ' ' || echo "Unknown nixos-rebuild error")
  
  # Log failed build with enhanced host information (WSL uses direct logging)
  if [ "$(hostname)" = "nixos" ]; then
      # WSL: Use direct logging to avoid batch processing hangs
      BYPASS_BATCH=1 scotty_log_event "build-error" "nixos-rebuild-${HOST_IDENTIFIER}" "$error_info"
      BYPASS_BATCH=1 log_build_performance "nixos-rebuild-${HOST_IDENTIFIER}" "$duration" "false" "nixos-rebuild-switch-failed" "Build failed during switch operation" "unknown"
  else
      # Native Linux: Use normal batched logging
      scotty_log_event "build-error" "nixos-rebuild-${HOST_IDENTIFIER}" "$error_info"
      log_build_performance "nixos-rebuild-${HOST_IDENTIFIER}" "$duration" "false" "nixos-rebuild-switch-failed" "Build failed during switch operation" "unknown"
  fi
  
  # Automatic Scotty logging disabled - use 'just log-commit' or invoke Scotty manually if needed
  # echo "=== CALLING SCOTTY FOR FAILURE ANALYSIS ==="
  # if command -v opencode >/dev/null 2>&1; then
  #   opencode run --agent scotty "Scotty, document this FAILED nixos-rebuild for ${HOST_IDENTIFIER}: Build duration ${duration} seconds, previous generation ${previous_gen}. Configuration changes attempted: ${config_files_changed}. Error: ${error_info}. Analyze what went wrong and provide troubleshooting recommendations." || echo "Scotty logging failed"
  # else
  #   echo "OpenCode not available - skipping detailed Scotty failure log"
  # fi
  
  echo "nixos-rebuild switch failed. Output:"
  cat "$output_file"
  rm "$output_file"
  exit 1
fi

rm "$output_file"
popd || exit
