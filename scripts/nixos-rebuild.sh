#!/usr/bin/env bash

# Parse command-line arguments
VERBOSE=false
REBUILD_SUBCOMMAND="switch"

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -t|--test)
            REBUILD_SUBCOMMAND="test"
            shift
            ;;
        -b|--boot)
            REBUILD_SUBCOMMAND="boot"
            shift
            ;;
        --dry-build)
            REBUILD_SUBCOMMAND="dry-build"
            shift
            ;;
        --dry-activate)
            REBUILD_SUBCOMMAND="dry-activate"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [-v|--verbose] [-t|--test] [-b|--boot] [--dry-build] [--dry-activate]"
            echo "  -v, --verbose       Show full output with --show-trace"
            echo "  -t, --test          Build and activate, but don't add to bootloader"
            echo "  -b, --boot          Build and add to bootloader, activate on next boot"
            echo "  --dry-build         Show what would be built without building"
            echo "  --dry-activate      Build but show what would be activated without activating"
            echo ""
            echo "Default: switch (build, activate, and add to bootloader)"
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
echo "NixOS Rebuilding ${HOST_IDENTIFIER} (subcommand: ${REBUILD_SUBCOMMAND})..."

# Build the nixos-rebuild command with optional verbose flags
NIXOS_CMD="sudo nixos-rebuild ${REBUILD_SUBCOMMAND} --flake .#${HOST}"
if [ "$VERBOSE" = true ]; then
  NIXOS_CMD="$NIXOS_CMD --show-trace"
fi

# Capture build output and success/failure with robust exit code handling
output_file=$(mktemp)

# Use pipefail to ensure we capture the exit code of nixos-rebuild, not tee
set -o pipefail

# Run nixos-rebuild and capture both output and exit code properly
echo "Starting nixos-rebuild ${REBUILD_SUBCOMMAND} for ${HOST_IDENTIFIER}..."
if [ "$VERBOSE" = true ]; then
  # Verbose mode: show all output
  if eval "$NIXOS_CMD" 2>&1 | tee "$output_file"; then
    nixos_rebuild_exit_code=${PIPESTATUS[0]}
  else
    nixos_rebuild_exit_code=${PIPESTATUS[0]}
  fi
else
  # Normal mode: capture output but don't show unless there's an error
  if eval "$NIXOS_CMD" > "$output_file" 2>&1; then
    nixos_rebuild_exit_code=$?
  else
    nixos_rebuild_exit_code=$?
  fi
fi

# Double-check the actual exit code from nixos-rebuild (not tee)
if [ "$nixos_rebuild_exit_code" -eq 0 ]; then
  build_success="true"
  
  # Extract generation number from nixos-rebuild output or list-generations
  gen=$(nixos-rebuild list-generations 2>/dev/null | grep -i "True" | awk '{print $1}' || echo "unknown")
  generation_number="$gen"
  
  # If we got a valid number, format it nicely, otherwise keep as "unknown"
  if [[ "$generation_number" =~ ^[0-9]+$ ]]; then
    gen="generation ${generation_number}"
  else
    gen="unknown generation"
    generation_number="unknown"
  fi
  
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
  
  # Only commit if this was a switch or boot operation (not test/dry-run)
  if [[ "$REBUILD_SUBCOMMAND" == "switch" || "$REBUILD_SUBCOMMAND" == "boot" ]]; then
    # Commit with enhanced generation info
    export AUTOMATED_COMMIT=true
    if [ -f "$(dirname "$0")/commit-enhance-lib.sh" ]; then
      source "$(dirname "$0")/commit-enhance-lib.sh"
      enhanced_msg=$(enhance_commit_message "auto(system): rebuild $HOST_IDENTIFIER generation $gen (${REBUILD_SUBCOMMAND})" "system-flake-rebuild.sh")
      if [ "$USE_NO_VERIFY" = true ]; then
        git commit -a --allow-empty --no-verify -m "$enhanced_msg" || true
      else
        git commit -a --allow-empty -m "$enhanced_msg" || true
      fi
    else
      # Fallback to basic message if enhancement library not available
      if [ "$USE_NO_VERIFY" = true ]; then
        git commit -a --allow-empty --no-verify -m "$HOST_IDENTIFIER: $gen (${REBUILD_SUBCOMMAND})" || true
      else
        git commit -a --allow-empty -m "$HOST_IDENTIFIER: $gen (${REBUILD_SUBCOMMAND})" || true
      fi
    fi
  else
    echo "ℹ️  Skipping git commit for ${REBUILD_SUBCOMMAND} operation"
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
  
  echo "nixos-rebuild ${REBUILD_SUBCOMMAND} failed. Output:"
  cat "$output_file"
  rm "$output_file"
  exit 1
fi

rm "$output_file"

# Print success message with operation details
if [[ "$REBUILD_SUBCOMMAND" == "dry-build" || "$REBUILD_SUBCOMMAND" == "dry-activate" ]]; then
  echo "✅ NixOS ${REBUILD_SUBCOMMAND} completed successfully for ${HOST_IDENTIFIER}! (${duration}s)"
elif [ "$REBUILD_SUBCOMMAND" == "test" ]; then
  echo "✅ NixOS test rebuild successful for ${HOST_IDENTIFIER}! Generation: $generation_number (${duration}s)"
  echo "ℹ️  Configuration activated but not added to bootloader"
elif [ "$REBUILD_SUBCOMMAND" == "boot" ]; then
  echo "✅ NixOS boot configuration built for ${HOST_IDENTIFIER}! Generation: $generation_number (${duration}s)"
  echo "ℹ️  Will activate on next reboot"
else
  echo "✅ NixOS rebuild successful for ${HOST_IDENTIFIER}! Generation: $generation_number (${duration}s)"
fi

popd || exit
