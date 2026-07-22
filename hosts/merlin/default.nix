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
    (configLib.relativeToRoot "hosts/common/optional/bspwm.nix") # Enable bspwm window manager
    (configLib.relativeToRoot "hosts/common/optional/firefox.nix")
    (configLib.relativeToRoot "hosts/common/optional/audio.nix") # Enable PipeWire audio system
    (configLib.relativeToRoot "hosts/common/optional/bluetooth.nix") # Enable Bluetooth support
    (configLib.relativeToRoot "hosts/common/optional/brightness-control.nix") # Enable brightness control for Framework laptops
    (configLib.relativeToRoot "hosts/common/optional/docker.nix") # Enable brightness control for Framework laptops
    # ../common/optional/xrdp.nix
    (configLib.relativeToRoot "containers/services/tdarr") # Enable brightness control for Framework laptops

    #gig users
    (configLib.relativeToRoot "hosts/common/users/gig")
    # (configLib.relativeToRoot "hosts/common/users/nixos")

    # wifi
    # (configLib.relativeToRoot "hosts/common/optional/wifi.nix")

    # # Bootloader.
    # (configLib.relativeToRoot "hosts/common/core/bootloader.nix")
  ];

  # gigpkgs container engine — the module is injected in flake.nix as
  # `inputs.nixpkgs.nixosModules.containers`. Provides the OCI runtime for
  # containers that run either as a service (via `gigpkgs.containers.services`
  # or the payloads under containers/services) or adhoc (podman CLI + the
  # nixos-generators images under containers/{buzz,mini}).
  gigpkgs.containers = {
    enable = true;
    backend = "podman";
    adhoc.enable = true;
  };

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

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable libinput for touchpad support with palm rejection
  services.libinput = {
    enable = true;
    touchpad = {
      # Enable palm rejection (disable while typing)
      disableWhileTyping = true;

      # Enable tap-to-click
      tapping = true;

      # Enable natural scrolling (disable if you prefer traditional scrolling)
      naturalScrolling = true;

      # Middle mouse button emulation (three finger tap/click)
      middleEmulation = true;

      # Disable touchpad while external mouse is connected (optional)
      # sendEventsMode = "disabled-on-external-mouse";
    };
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
