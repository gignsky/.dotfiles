{ inputs, lib, config, pkgs, outputs, ...}: {
  imports = [
    ../../common/core
    ../../common/users/gig
    inputs.home-manager.nixosModules.home-manager
  ];

  networking.hostName = "nixos";

  # fixes vscode remote wsl stuff
  programs.nix-ld = {
    enable = true;
    package = pkgs.nix-ld-rs;
  };

  nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Opinionated: disable global registry
      flake-registry = "";

    };

    channel.enable = false;

  };

  # System-wide packages installed by root
  environment.systemPackages = [
    pkgs.wget
    pkgs.bat
    pkgs.tree
    pkgs.magic-wormhole
    pkgs.git

    # unstable packages
    # pkgs.just
    # pkgs.unstable.just # need unstable for latest version
  ];

#   # I think this is unneccecary if I'm going with standalone home-manager rather than flake os module home-manager
#   home-manager = {
#     extraSpecialArgs = { inherit inputs outputs; };
#     users = {
#       # Import your home-manager configuration
#       gig = import ../../../home/gig/ganosLal/wsl.nix;
#     };
#   };

  system.stateVersion = "24.05";
}
