# Custom Nix configuration for install
{ lib, ... }: {
  # This ensures that when nixos-anywhere runs, unfree packages are allowed
  nixpkgs.config = {
    allowUnfree = true;
    # We need to explicitly list broadcom-sta here
    allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "broadcom-sta" ];
  };

  # Make sure redistributable firmware is enabled
  hardware.enableRedistributableFirmware = true;
}
