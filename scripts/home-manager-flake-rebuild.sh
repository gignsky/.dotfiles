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
echo "Home-Manager Rebuilding..."
output_file=$(mktemp)
if ! home-manager switch --flake .#gig@"$HOST" > "$output_file" 2>&1; then
  echo "home-manager switch failed. Output:"
  cat "$output_file"
  exit 1
fi
rm "$output_file"
gen=$(home-manager generations 2>/dev/null | head -n 1)
git commit -a --allow-empty -m "gig@$HOST: $gen" || true
popd || exit
