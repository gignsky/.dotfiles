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
sudo nixos-rebuild switch -vv --flake .#"$HOST" | sudo tee nixos-switch.log || (
 grep --color error && false) < nixos-switch.log
gen=$(nixos-rebuild list-generations 2>/dev/null | grep current)
git commit -am "$HOST: $gen"
popd || exit
