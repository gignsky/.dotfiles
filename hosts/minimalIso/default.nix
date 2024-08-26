{ inputs, lib, config, pkgs, ...}: {
  imports = [
    ../common/core
    ../common/optional/gui.nix
    ../common/optional/xrdp.nix
    ../common/optional/sshd-with-passwords.nix
    ../common/optional/sshd-with-root-login.nix
    ../common/users/gig
  ];

  networking.hostName = "nix-minimus";

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

  system.stateVersion = "24.05";
}
