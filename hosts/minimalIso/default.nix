{ inputs, lib, configLib, ...}: {
  imports = [
    (configLib.relativeToRoot "hosts/common/users/gig")
    (configLib.relativeToRoot "hosts/common/core")
    (configLib.relativeToRoot "hosts/common/optional/gui.nix")
    (configLib.relativeToRoot "hosts/common/optional/xrdp.nix")
    (configLib.relativeToRoot "hosts/common/optional/sshd-with-passwords.nix")
    (configLib.relativeToRoot "hosts/common/optional/sshd-with-root-login.nix")
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
