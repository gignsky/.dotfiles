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

  home-manager = {
    extraSpecialArgs = { inherit inputs outputs; };
    users = {
      # Import your home-manager configuration
      gig = import ../../../home/gig/ganosLal/wsl.nix;
    };
  };

  system.stateVersion = "24.05";
}
