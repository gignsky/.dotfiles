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
    scotty_log_event() { echo "[$1] $*" >&2; }
    log_build_performance() { echo "Build: $1 took $2 seconds (success: $3)" >&2; }
fi

# Enhanced host detection with intelligent WSL mapping
export HOST=$(detect_flake_target "$1")
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
            echo "  2. First authenticate sudo manually: sudo true"
            echo "  3. Run the rebuild command directly: sudo nixos-rebuild switch --flake .#${HOST}"
            echo ""
            exit 1
        fi
    else
        echo "✅ Sudo already authenticated for ${HOST_IDENTIFIER}."
    fi
}

authenticate_sudo

failable-pre-commit() {
  nix develop -c pre-commit run --all-files
}

set -e
pushd . || exit

# Log build start with enhanced host information (WSL uses direct logging)
start_time=$(date +%s)
if [ "$(hostname)" = "nixos" ]; then
    # WSL: Use direct logging to avoid batch processing hangs
    BYPASS_BATCH=1 scotty_log_event "build-start" "nixos-rebuild-${HOST_IDENTIFIER}"
else
    # Native Linux: Use normal batched logging
    scotty_log_event "build-start" "nixos-rebuild-${HOST_IDENTIFIER}"
fi

# Capture previous generation for comparison
previous_gen=$(nixos-rebuild list-generations 2>/dev/null | grep current | grep -o '[0-9]*' | head -n 1 || echo "0")

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

# Capture build output and success/failure
output_file=$(mktemp)
if sudo nixos-rebuild switch --flake .#"$HOST" | tee "$output_file" 2>&1; then
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
  
  # Call Scotty to create detailed engineering log
  echo "=== CALLING SCOTTY FOR DETAILED ENGINEERING LOG ==="
  if command -v opencode >/dev/null 2>&1; then
    opencode run --agent scotty "Scotty, document this successful nixos-rebuild for ${HOST_IDENTIFIER}: Generation ${previous_gen} → ${generation_number}, build duration ${duration} seconds. Configuration changes since last rebuild: ${config_files_changed}. Files changed: ${detailed_diff}" || echo "Scotty logging failed, continuing..."
  else
    echo "OpenCode not available - skipping detailed Scotty log"
  fi
  
  # Commit with enhanced generation info (skip pre-commit hooks to avoid conflicts)
  export AUTOMATED_COMMIT=true
  if [ -f "$(dirname "$0")/commit-enhance-lib.sh" ]; then
    source "$(dirname "$0")/commit-enhance-lib.sh"
    enhanced_msg=$(enhance_commit_message "auto(system): rebuild $HOST_IDENTIFIER generation $gen" "system-flake-rebuild.sh")
    git commit -a --allow-empty --no-verify -m "$enhanced_msg" || true
  else
    # Fallback to basic message if enhancement library not available
    git commit -a --allow-empty --no-verify -m "$HOST_IDENTIFIER: $gen" || true
  fi
else
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
  
  # Call Scotty to document the failure
  echo "=== CALLING SCOTTY FOR FAILURE ANALYSIS ==="
  if command -v opencode >/dev/null 2>&1; then
    opencode run --agent scotty "Scotty, document this FAILED nixos-rebuild for ${HOST_IDENTIFIER}: Build duration ${duration} seconds, previous generation ${previous_gen}. Configuration changes attempted: ${config_files_changed}. Error: ${error_info}. Analyze what went wrong and provide troubleshooting recommendations." || echo "Scotty logging failed"
  else
    echo "OpenCode not available - skipping detailed Scotty failure log"
  fi
  
  echo "nixos-rebuild switch failed. Output:"
  cat "$output_file"
  rm "$output_file"
  exit 1
fi

rm "$output_file"
popd || exit
