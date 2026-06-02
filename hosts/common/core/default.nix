{ configLib, pkgs, inputs, ... }:

{
  imports = configLib.scanPaths ./.;
  # ++ [ inputs.home-manager.nixosModules.home-manager ] # TODO: IMPORT THIS when home-manager is integrated as a module
  # ++ (builtins.attrValues outputs.nixosModules); # TODO: IMPORT THIS when implementing the modules subdirectory

  nixpkgs = {
    overlays = [ inputs.gigpkgs.overlays.default ];
    config = {
      allowUnfree = true;
    };
  };

  environment.systemPackages = with pkgs; [
    nix
    # dig
  ];

  hardware.enableRedistributableFirmware = true;
}
