# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
  inputs,
  lib,
  config,
  configLib,
  ...
}:
{
  # You can import other NixOS modules here
  imports = [
    # If you want to use modules from other flakes (such as nixos-hardware):
    # inputs.hardware.nixosModules.common-cpu-amd
    # inputs.hardware.nixosModules.common-ssd

    # You can also split up your configuration and import pieces of it here:
    # ./users.nix

    # Import your generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix
    # core utils
    (configLib.relativeToRoot "hosts/common/core")

    # optional
    (configLib.relativeToRoot "hosts/common/optional/xfce.nix")
    (configLib.relativeToRoot "hosts/common/optional/firefox.nix")
    # ../common/optional/xrdp.nix

    #gig users
    (configLib.relativeToRoot "hosts/common/users/gig")
    # (configLib.relativeToRoot "hosts/common/users/nixos")

    # wifi
    # (configLib.relativeToRoot "hosts/common/optional/wifi.nix")

    # # Bootloader.
    # (configLib.relativeToRoot "hosts/common/core/bootloader.nix")
  ];

  networking = {
    hostName = "merlin";
    # hostId should be a unique 8-character (hexadecimal) string, especially if using ZFS.
    # You can generate one with: head -c4 /dev/urandom | od -An -tx1 | tr -d ' \n'
    hostId = "81a45b83";
    networkmanager.enable = true;
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  nix =
    let
      flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
    in
    {
      settings = {
        # Enable flakes and new 'nix' command
        experimental-features = "nix-command flakes";
        # Opinionated: disable global registry
        flake-registry = "";
        # Workaround for https://github.com/NixOS/nix/issues/9574
        nix-path = config.nix.nixPath;
      };
      # Opinionated: disable channels
      channel.enable = false;

      # Opinionated: make flake registry and nix path match flake inputs
      registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
    };

  # fileSystems = {
  #   "/" = {
  #     device = "zroot/root";
  #     fsType = "zfs";
  #   };
  #   "/boot" = {
  #     device = "/dev/nvme0n1p2";
  #     fsType = "vfat";
  #   };
  #   "/nix/store" = {
  #     device = "zroot/nix";
  #     fsType = "zfs";
  #   };
  # };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.05";
}
