{ configLib, pkgs, ... }:

{
  imports = configLib.scanPaths ./.;
  # ++ [ inputs.home-manager.nixosModules.home-manager ] # TODO: IMPORT THIS when home-manager is integrated as a module
  # ++ (builtins.attrValues outputs.nixosModules); # TODO: IMPORT THIS when implementing the modules subdirectory

  nixpkgs = {
    # you can add global overlays here
    # overlays = builtins.attrValues outputs.overlays;
    config = {
      allowUnfree = true;
    };
  };

  environment.systemPackages = [ pkgs.nix ];

  hardware.enableRedistributableFirmware = true;
}
