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

set -e
pushd ~/.dotfiles || exit
git diff -U0 ./*glob*.nix
echo "NixOS Rebuilding..."
output_file=$(mktemp)
if ! sudo nixos-rebuild switch --flake .#"$HOST" | tee "$output_file" 2>&1; then
    echo "nixos-rebuild switch failed. Output:"
    cat "$output_file"
    exit 1
fi
rm "$output_file"
gen=$(nixos-rebuild list-generations 2>/dev/null | grep current)
git commit -am "$HOST: $gen"
popd || exit
