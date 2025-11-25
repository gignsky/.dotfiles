#!/usr/bin/env bash

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
    echo "🔐 NixOS test rebuild requires sudo access..."
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
            echo "  3. Run the rebuild command directly: sudo nixos-rebuild test --flake .#\$(hostname)"
            echo ""
            exit 1
        fi
    else
        echo "✅ Sudo already authenticated."
    fi
}

authenticate_sudo

sudo nixos-rebuild --impure --flake .#"$HOST" test
