{ inputs, lib, config, pkgs, ...}: {
  imports = [
    ../../common/core
    ../../common/users/gig
  ];

  networking.hostName = "wsl-ganosLal";

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

    system.stateVersion = "24.05";
  };
}
