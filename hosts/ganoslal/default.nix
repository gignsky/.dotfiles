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
    # NOTE: xfce.nix was tried here as a GUI for verifying the monitor layout,
    # but xfce4-session blanks every display on this dual-GPU setup. bspwm
    # drives all four monitors correctly, so leave XFCE out — that also keeps a
    # session that cannot work off the display manager's session list.
    # (configLib.relativeToRoot "hosts/common/optional/xfce.nix")
    (configLib.relativeToRoot "hosts/common/optional/bspwm.nix") # Enable bspwm window manager
    (configLib.relativeToRoot "hosts/common/optional/audio.nix") # Enable PipeWire audio system
    (configLib.relativeToRoot "hosts/common/optional/firefox.nix")
    # ../common/optional/xrdp.nix
    # NOTE: autorandr is deliberately not imported — this host has a fixed
    # 4-monitor set, and two of its panels have byte-identical EDIDs so
    # autorandr cannot tell them apart anyway.

    #gig users
    (configLib.relativeToRoot "hosts/common/users/gig")
    # (configLib.relativeToRoot "hosts/common/users/nixos")

    # wifi
    # (configLib.relativeToRoot "hosts/common/optional/wifi.nix")

    # # Bootloader.
    # (configLib.relativeToRoot "hosts/common/core/bootloader.nix")
  ];

  networking = {
    hostName = "ganoslal";
    # hostId should be a unique 8-character (hexadecimal) string, especially if using ZFS.
    # You can generate one with: head -c4 /dev/urandom | od -An -tx1 | tr -d ' \n'
    hostId = "f12caece";
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

  services.xserver = {

    # Configure keymap in X11
    xkb = {
      layout = "us";
      variant = "";
    };

    # Both GPUs in this machine are NVIDIA (RTX 3060 Ti + GTX 970); the single
    # nvidia driver handles both. See ./nvidia.nix for the multi-GPU wiring.
    videoDrivers = [ "nvidia" ];
  };

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
