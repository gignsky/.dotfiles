{ inputs, lib, config, pkgs, outputs, ...}: {
  imports = [
    ../../common/core
    ../../common/users/gig.nix
    # inputs.nixos-wsl.modules
    # inputs.home-manager.nixosModules.home-manager
  ];

  networking.hostName = "nixos";

  # fixes vscode remote wsl stuff
  programs.nix-ld = {
    enable = true;
    package = pkgs.nix-ld-rs;
  };

  wsl.enable = true;  # Redunent with nixosModules.default on the flake.nix level
  wsl.defaultUser = "gig";

  nix = let
    _flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Opinionated: disable global registry
      flake-registry = "";

    };

    channel.enable = false;

  };

#   # I think this is unneccecary if I'm going with standalone home-manager rather than flake os module home-manager
#   home-manager = {
#     extraSpecialArgs = { inherit inputs outputs; };
#     users = {
#       # Import your home-manager configuration
#       gig = import ../../../home/gig/ganosLal/wsl.nix;
#     };
#   };

  # nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "24.05";
}
