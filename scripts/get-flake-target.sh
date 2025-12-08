#!/usr/bin/env bash

# Simple script to get the correct flake target for the current environment
# Used by justfile commands that need the proper host target

# Source host detection library
HOST_DETECTION_LIB_PATHS=(
    "${HOME}/.dotfiles/scripts/host-detection-lib.sh"
    "$(dirname "$0")/host-detection-lib.sh"
)

for lib_path in "${HOST_DETECTION_LIB_PATHS[@]}"; do
    if [ -n "$lib_path" ] && [ -f "$lib_path" ]; then
        source "$lib_path"
        break
    fi
done

# If host detection library not found, provide fallback
if ! command -v detect_flake_target >/dev/null 2>&1; then
    detect_flake_target() {
        if [ -n "$1" ]; then
            echo "$1"
        elif [ "$(hostname)" = "nixos" ]; then
            echo "wsl"
        else
            echo "$(hostname)"
        fi
    }
fi

# Output the correct flake target (can be used as `host-detection.sh` in justfile)
detect_flake_target "$1"
