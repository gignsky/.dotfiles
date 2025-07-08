#!/usr/bin/env bash
set -euo pipefail

branch="$(git rev-parse --abbrev-ref HEAD)"

if [[ "$branch" == "main" ]]; then
  echo "Running nix flake check on branch: $branch"
  nix flake check
else
  echo "Skipping nix flake check on branch: $branch"
fi
