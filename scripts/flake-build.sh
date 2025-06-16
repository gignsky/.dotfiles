#!/usr/bin/env bash

if [ -n "$1" ]; then
	if [ "$1" = "file" ]; then
		PATH_USED=TRUE
		FLAKE_PATH="$(pwd)/$2"
	else
		PATH_USED=FALSE
		PACKAGE="$1"
	fi
else
	PATH_USED=FALSE
	PACKAGE=""
fi
export PATH_USED PACKAGE FLAKE_PATH

if [ "$PATH_USED" = TRUE ]; then
	echo "Building flake at $FLAKE_PATH"
	# nix build --file "$FLAKE_PATH"
else
	nix build .#"$PACKAGE"
fi
