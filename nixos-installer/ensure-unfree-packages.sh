#!/usr/bin/env bash
set -e

# This script ensures that the Broadcom STA driver is properly installed
# even if the nixos-anywhere process fails to handle unfree packages

echo "Ensuring unfree packages are allowed..."
mkdir -p /mnt/etc/nixos/
cat > /mnt/etc/nixos/unfree-config.nix << EOF
{ config, lib, pkgs, ... }:

{
  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "broadcom-sta" ];
  };
  
  # Ensure broadcom module is included
  boot.kernelModules = [ "kvm-intel" "wl" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
}
EOF

# Update the configuration.nix to import our unfree config
if [ -f /mnt/etc/nixos/configuration.nix ]; then
  sed -i '/^.*imports.*/a \    ./unfree-config.nix' /mnt/etc/nixos/configuration.nix
  echo "Added unfree-config.nix import to configuration.nix"
fi

echo "Unfree package configuration updated successfully"
