# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
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
    # (configLib.relativeToRoot "hosts/common/optional/xfce.nix")
    (configLib.relativeToRoot "hosts/common/optional/niri.nix") # Enable niri window manager (Wayland)
    # autorandr is bspwm-only (its postswitch hook runs `bspc wm -r`); niri
    # configures outputs itself and merlin is a single-eDP-1 laptop, so it's
    # dropped rather than ported.
    (configLib.relativeToRoot "hosts/common/optional/dns.nix") # Pin LAN DNS to the router
    (configLib.relativeToRoot "hosts/common/optional/firefox.nix")
    (configLib.relativeToRoot "hosts/common/optional/audio.nix") # Enable PipeWire audio system
    (configLib.relativeToRoot "hosts/common/optional/bluetooth.nix") # Enable Bluetooth support
    (configLib.relativeToRoot "hosts/common/optional/brightness-control.nix") # Enable brightness control for Framework laptops
    (configLib.relativeToRoot "hosts/common/optional/docker.nix") # Enable brightness control for Framework laptops
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

  # Tailscale configuration
  tailscale.enable = false;

  # Grub installation
  boot.loader = {
    # Bootloader.
    systemd-boot.enable = false;
    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      efiInstallAsRemovable = false;
      useOSProber = true; # Automatically detect Windows and other OSes
      configurationLimit = 20; # Limit boot menu entries to last 20 generations

      # default config
      default = "saved";
      extraConfig = ''
        GRUB_SAVEDEFAULT=true
      '';
    };
    efi.canTouchEfiVariables = true;
  };

  # Keyboard layout and touchpad behavior now live in niri's own KDL config
  # (home/gig/common/optional/niri.nix, `input.keyboard.xkb` /
  # `input.touchpad`) -- `services.xserver.xkb` and `services.libinput` only
  # take effect under `services.xserver`, which niri doesn't use.

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # nix daemon settings, flake registry, and nix path are configured centrally
  # in hosts/common/core/nix.nix.

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
