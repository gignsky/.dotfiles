#! /bin/sh

# if no extra args just run 'nix flake show --all-systems' in the current directory, else if there is an argument to this script run 'nix flake show --all-systems $1'
if [ $# -eq 0 ]; then
  nix flake show --all-systems
else
  nix flake show --all-systems $1
fi
