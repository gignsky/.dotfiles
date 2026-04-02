# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
  inputs,
  lib,
  config,
  configLib,
  pkgs,
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
    (configLib.relativeToRoot "hosts/common/spacedock")

    # optional
    # (configLib.relativeToRoot "hosts/common/optional/docker.nix")
    # # (configLib.relativeToRoot "hosts/common/optional/gitlab.nix")
    # (configLib.relativeToRoot "hosts/common/optional/minecraft.nix")
    # (configLib.relativeToRoot "hosts/common/optional/samba.nix")

    # containers
    # (configLib.relativeToRoot "containers/services")

    #users
    (configLib.relativeToRoot "hosts/common/users/gig")
    # (configLib.relativeToRoot "hosts/common/users/dotunwrap")
  ];
  boot = {
    # Bootloader.
    loader.grub = {
      enable = true;
      device = "/dev/sda"; # Install GRUB on the primary disk (adjust if your disk is different)
      # efiSupport = false; # Disabled for legacy BIOS (this is the default)
    };

    kernelPackages = pkgs.linuxPackages_6_12;
  };

  tailscale.enable = false;

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

  # # TODO Future Filesystem structure needs to be implemented
  # fileSystems = {
  #   "/" = {
  #     device = "zroot/root";
  #     fsType = "zfs";
  #   };
  #   "/boot" = {
  #     device = "/dev/nvme1n1p2";
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
