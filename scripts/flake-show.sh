if [ ! -z $1 ]; then
	if [ $1 == "all" ]; then
        export ALL=TRUE
    else
        export ALL=FALSE
    fi
else
	export ALL=FALSE
fi

if [ $ALL == TRUE ]; then
    nix flake show
else
    nix flake show --all-systems
fi
