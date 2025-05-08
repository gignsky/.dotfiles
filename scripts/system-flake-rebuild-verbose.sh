#!/usr/bin/env bash

if [ ! -z $1 ]; then
	export HOST=$1
else
	if [ $(hostname) == "nixos" ]; then
		export HOST="wsl"
	else
		export HOST=$(hostname)
	fi
fi

sudo nixos-rebuild --impure --flake .#$HOST switch -vv
