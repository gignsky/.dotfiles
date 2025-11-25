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
git diff -U0 ./*glob*.nix
echo "Running pre-commit on all files"
failable-pre-commit || true
echo "NixOS Rebuilding..."
output_file=$(mktemp)
if ! sudo nixos-rebuild switch --flake .#"$HOST" | tee "$output_file" 2>&1; then
  echo "nixos-rebuild switch failed. Output:"
  cat "$output_file"
  exit 1
fi
rm "$output_file"
gen=$(nixos-rebuild list-generations 2>/dev/null | grep current)
git commit -a --allow-empty -m "$HOST: $gen" || true
popd || exit
