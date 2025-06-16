#!/usr/bin/env bash
export PATH="$PATH:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin"
exec nix "$@"
