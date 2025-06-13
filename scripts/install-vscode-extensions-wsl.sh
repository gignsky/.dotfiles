#!/usr/bin/env bash
# Install VS Code extensions from the Nix single source of truth (for WSL)
# Usage: ./install-vscode-extensions-wsl.sh

EXT_LIST_FILE="$(dirname "$0")/../home/gig/common/optional/vscode/vscode-extensions-list.nix"

if [ ! -f "$EXT_LIST_FILE" ]; then
  echo "Extension list not found: $EXT_LIST_FILE"
  exit 1
fi

# Read the Nix list and install each extension
EXT_IDS=$(nix eval --raw --expr "builtins.toJSON (import $EXT_LIST_FILE)")

for ext in $(echo "$EXT_IDS" | jq -r '.[]'); do
  code --install-extension "$ext"
done

echo "All extensions installed from $EXT_LIST_FILE."
