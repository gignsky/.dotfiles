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

git diff -U0 ./*glob*.nix
echo "Running pre-commit on all files"
failable-pre-commit || true
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
  
  # Commit with enhanced generation info
  export AUTOMATED_COMMIT=true
  if [ -f "$(dirname "$0")/commit-enhance-lib.sh" ]; then
    source "$(dirname "$0")/commit-enhance-lib.sh"
    enhanced_msg=$(enhance_commit_message "auto(system): rebuild $HOST_IDENTIFIER generation $gen" "system-flake-rebuild.sh")
    git commit -a --allow-empty -m "$enhanced_msg" || true
  else
    # Fallback to basic message if enhancement library not available
    git commit -a --allow-empty -m "$HOST_IDENTIFIER: $gen" || true
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
  
  echo "nixos-rebuild switch failed. Output:"
  cat "$output_file"
  rm "$output_file"
  exit 1
fi

rm "$output_file"
popd || exit
