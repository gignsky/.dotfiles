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
home-manager switch --flake .#gig@"$HOST" | sudo tee home-manager-switch.log || (
 grep --color error && false) < home-manager-switch.log
gen=$(home-manager generations 2>/dev/null | head -n 1)
git commit -am "gig@$HOST: $gen"
popd || exit
