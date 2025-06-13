{ pkgs
, lib
, configLib
, configVars
, inputs
, ...
}:
let
  inherit (configVars.networking) sshPort;
in
{
  # The default compression-level is (6) and takes too long on some machines (>30m). 3 takes <2m
  # isoImage.squashfsCompression = "zstd -Xcompression-level 3";

  nixpkgs = {
    hostPlatform = lib.mkDefault "x86_64-linux";
    config.allowUnfree = true;
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_6_1; # pinned to a specific kernel version to avoid zfs-kernel module being marked as broken
    supportedFilesystems = lib.mkForce [
      "btrfs"
      "vfat"
      "zfs"
    ];
  };

  networking = {
    hostName = "full-vm";
  };

  environment.systemPackages = with pkgs; [
    magic-wormhole
    btop
    bat
  ];

  environment.shellAliases = {
    cat = "bat";
    ll = "ls -lh";
    lla = "ls -lha";
  };

  systemd = {
    services.sshd.wantedBy = lib.mkForce [ "multi-user.target" ];
    # gnome power settings to not turn off screen
    targets = {
      sleep.enable = false;
      suspend.enable = false;
      hibernate.enable = false;
      hybrid-sleep.enable = false;
    };
  };
  imports = [
    (configLib.relativeToRoot "hosts/common/core")
    (configLib.relativeToRoot "hosts/common/users/gig")
    (configLib.relativeToRoot "hosts/common/optional/samba.nix")
    (configLib.relativeToRoot "hosts/common/optional/sshd-with-root-login.nix")
    # (configLib.relativeToRoot "hosts/common/optional/neofetch.nix")
    # inputs.nixos-wsl.modules
    # inputs.home-manager.nixosModules.home-manager
  ];
  nix =
    let
      _flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
    in
    {
      settings = {
        # Enable flakes and new 'nix' command
        experimental-features = "nix-command flakes";
        # Opinionated: disable global registry
        flake-registry = "";
        trusted-users = [ "gig" ];

      };

      channel.enable = false;

    };
}
