#!/usr/bin/env bash

# Host Detection Library for NixOS Dotfiles
# Provides intelligent host detection for WSL environments and flake target mapping

# Detect if we're running in a WSL environment
is_wsl_environment() {
    # Multiple WSL detection methods for reliability
    [[ -n "${WSL_DISTRO_NAME:-}" ]] || \
    [[ "$(uname -r)" == *microsoft* ]] || \
    [[ -f /proc/version ]] && grep -q microsoft /proc/version || \
    command -v cmd.exe >/dev/null 2>&1
}

# Detect the physical Windows host machine name (for WSL instances)
detect_physical_host() {
    # Method 1: Windows interop (most reliable for WSL2)
    if command -v cmd.exe >/dev/null 2>&1; then
        local windows_hostname
        windows_hostname=$(cmd.exe /c hostname 2>/dev/null | tr -d '\r' | tr '[:upper:]' '[:lower:]')
        if [[ -n "$windows_hostname" ]]; then
            echo "$windows_hostname"
            return 0
        fi
    fi
    
    # Method 2: Manual override file (fallback)
    if [[ -f ~/.dotfiles/.physical-host ]]; then
        cat ~/.dotfiles/.physical-host
        return 0
    fi
    
    # Method 3: Use actual hostname as fallback
    echo "$(hostname)"
}

# Determine the correct flake target based on environment and user input
detect_flake_target() {
    local provided_host="$1"
    local actual_hostname="$(hostname)"
    
    # If user explicitly provided a host, use it
    if [[ -n "$provided_host" ]]; then
        echo "$provided_host"
        return 0
    fi
    
    # Auto-detect WSL and map to 'wsl' flake target
    if [[ "$actual_hostname" == "nixos" ]] && is_wsl_environment; then
        echo "wsl"
        return 0
    fi
    
    # For other hosts, use actual hostname
    echo "$actual_hostname"
}

# Generate a descriptive host identifier for logging (includes physical host for WSL)
get_host_identifier() {
    local flake_target="$1"
    local physical_host
    
    if is_wsl_environment; then
        physical_host=$(detect_physical_host)
        echo "${flake_target}@${physical_host}"
    else
        echo "$flake_target"
    fi
}

# Enhanced logging function that includes physical host information
log_with_host_context() {
    local log_level="$1"
    local message="$2"
    local flake_target="${3:-$(detect_flake_target)}"
    local host_id
    
    host_id=$(get_host_identifier "$flake_target")
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$log_level] ($host_id) $message"
}
