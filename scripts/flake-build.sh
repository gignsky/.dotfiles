#!/usr/bin/env bash

if [ ! -z $1 ]; then
	export PACKAGE=$1
else
	export PACKAGE=""
fi

nix build .#$PACKAGE
