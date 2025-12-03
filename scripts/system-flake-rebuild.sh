#!/usr/bin/env bash

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
    log_build_performance() { echo "Build: $1 took $2 seconds (success: $3)" >&2; }
fi

if [ -n "$1" ]; then
  export HOST="$1"
else
  if [ "$(hostname)" = "nixos" ]; then
    HOST="wsl"
  else
    HOST="$(hostname)"
  fi
  export HOST
fi

authenticate_sudo() {
    echo "🔐 NixOS rebuild requires sudo access..."
    if ! sudo -n true 2>/dev/null; then
        if [ -t 0 ] && [ -t 1 ]; then
            # Interactive terminal available
            echo "Please enter your password to authenticate sudo:"
            sudo true || {
                echo "❌ Sudo authentication failed. Exiting."
                exit 1
            }
            echo "✅ Sudo authentication successful."
        else
            # No interactive terminal - provide helpful guidance
            echo ""
            echo "❌ No interactive terminal available for sudo authentication."
            echo ""
            echo "To fix this, please choose one of the following options:"
            echo "  1. Run this command from an interactive terminal"
            echo "  2. First authenticate sudo manually: sudo true"
            echo "  3. Run the rebuild command directly: sudo nixos-rebuild switch --flake .#\$(hostname)"
            echo ""
            exit 1
        fi
    else
        echo "✅ Sudo already authenticated."
    fi
}

authenticate_sudo

failable-pre-commit() {
  nix develop -c pre-commit run --all-files
}

set -e
pushd . || exit

# Log build start
start_time=$(date +%s)
scotty_log_event "build-start" "nixos-rebuild-${HOST}"

git diff -U0 ./*glob*.nix
echo "Running pre-commit on all files"
failable-pre-commit || true
echo "NixOS Rebuilding..."

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
  
  # Log successful build
  scotty_log_event "build-complete" "nixos-rebuild-${HOST}" "$duration" "$build_success" "$generation_number"
  
  # Commit with enhanced generation info
  export AUTOMATED_COMMIT=true
  if [ -f "$(dirname "$0")/commit-enhance-lib.sh" ]; then
    source "$(dirname "$0")/commit-enhance-lib.sh"
    enhanced_msg=$(enhance_commit_message "auto(system): rebuild $HOST generation $gen" "system-flake-rebuild.sh")
    git commit -a --allow-empty -m "$enhanced_msg" || true
  else
    # Fallback to basic message if enhancement library not available
    git commit -a --allow-empty -m "$HOST: $gen" || true
  fi
else
  build_success="false"
  end_time=$(date +%s)
  duration=$((end_time - start_time))
  
  # Extract error information from output
  error_info=$(tail -n 5 "$output_file" | tr '\n' ' ' || echo "Unknown nixos-rebuild error")
  
  # Log failed build
  scotty_log_event "build-error" "nixos-rebuild-${HOST}" "$error_info"
  log_build_performance "nixos-rebuild-${HOST}" "$duration" "false" "nixos-rebuild-switch-failed" "Build failed during switch operation" "unknown"
  
  echo "nixos-rebuild switch failed. Output:"
  cat "$output_file"
  rm "$output_file"
  exit 1
fi

rm "$output_file"
popd || exit
