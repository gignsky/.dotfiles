#!/usr/bin/env bash

if [ ! -z $1 ]; then
	if [ $1 == "file" ]; then
		export PATH_USED=TRUE
		export PATH=$(pwd)/$2
	else
		export PATH_USED=FALSE
		export PACKAGE=$1
	fi
else
	export PATH_USED=FALSE
	export PACKAGE=""
fi

if [ $PATH_USED == TRUE ]; then
	echo "Building flake at $PATH"
	# nix build --file $PATH
else
	nix build .#$PACKAGE
fi
