{
  config,
  lib,
  pkgs,
  ...
}:
# Dual-NVIDIA GPU configuration for ganoslal's 4-monitor setup.
# There is no AMD GPU in this machine — both cards are NVIDIA:
#
#   RTX 3060 Ti  PCI 2d:00.0  (decimal 45)  <- pinned as the X primary below
#   GTX 970      PCI 23:00.0  (decimal 35)
#
# IMPORTANT: NVIDIA derives RandR output names from provider order, so the
# names below are only stable as long as the primary GPU is pinned. X defaults
# to the lowest PCI bus, which would pick the GTX 970 (0x23 < 0x2d) and rename
# every output — that is exactly what broke this host previously. The BusID in
# deviceSection is what keeps the naming below true.
#
#   RTX 3060 Ti (NVIDIA-0, Source Output)
#     DP-2      5120x1440@144  ultrawide, bottom center
#     HDMI-0    1920x1080@60   top left
#     DP-1      1920x1080@60   top right
#   GTX 970 (NVIDIA-G0, Sink Output — driven via PRIME output offload)
#     DP-1-1    1920x1080@60   top center (LG IPS235)
#
# Monitor modes and positions are NOT set here. XFCE's display settings
# (xfsettingsd / xfconf) owns the layout; nothing in Nix should fight it.
#
# Ref: https://nixos.wiki/wiki/Nvidia
{
  nixpkgs.config.allowUnfree = lib.mkForce true;
  nixpkgs.config.nvidia.acceptLicense = true;
  boot.kernelParams = [ "nvidia-drm.fbdev=1" ];

  hardware = {
    nvidia = {
      # Use latest stable drivers (535+ with modern features)
      package = config.boot.kernelPackages.nvidiaPackages.stable;

      # Enable kernel modesetting (required for 535+, prevents screen tearing)
      modesetting.enable = true;

      # Use proprietary kernel modules (GTX 970 doesn't support open modules)
      # RTX 3060 Ti could use open=true with driver 560+, but GTX 970 requires proprietary
      open = false;

      # Enable NVIDIA Control Panel
      nvidiaSettings = true;

      # NOTE: PRIME is for hybrid laptop configurations (integrated + discrete GPU).
      # For two discrete NVIDIA GPUs we don't use hardware.nvidia.prime at all —
      # the second card is attached at runtime as a RandR output sink instead
      # (see displayManager.sessionCommands below).

      # Enable power management for better stability
      powerManagement = {
        enable = lib.mkDefault true;
      };
    };

    # Graphics subsystem configuration
    graphics = {
      enable = true;
      enable32Bit = true; # Support for 32-bit applications/games
    };
  };

  # Configure X11 to recognize both NVIDIA GPUs
  services.xserver = {
    # Expose outputs from BOTH GPUs on a single unified screen. Without this,
    # X11 only ever sees the primary GPU's outputs.
    serverFlagsSection = ''
      Option "AllowMouseOpenFail" "True"
      Option "AutoAddGPU" "True"
    '';

    # Let the nvidia driver bring up the screen even with no monitor attached
    # to the primary output at server start.
    screenSection = ''
      Option "AllowEmptyInitialConfiguration" "True"
    '';

    # Spliced into the generated Section "Device" / Identifier "Device-nvidia[0]".
    deviceSection = ''
      # Pin the RTX 3060 Ti (PCI 2d:00.0) as X's primary device. X wants this in
      # DECIMAL, so 0x2d -> 45. Without it X picks the lowest bus (the GTX 970)
      # and every RandR output gets renamed.
      BusID "PCI:45:0:0"
      # Probe and enable all connected outputs across all GPUs
      Option "ProbeAllGpus" "True"
      Option "AllowExternalGpus" "True"
    '';

    # Runs per-session, after login, before the window manager.
    displayManager.sessionCommands = ''
      # Attach the secondary GPU (GTX 970) to the primary GPU's X screen so its
      # outputs are usable. This is provider-name based, not output-name based,
      # so it is unaffected by output renaming.
      ${pkgs.xorg.xrandr}/bin/xrandr --setprovideroutputsource NVIDIA-G0 NVIDIA-0 || true

      # Deliberately no mode/position commands here — the desktop environment
      # owns the monitor layout. Log what X actually ended up with so display
      # problems can be diagnosed without a working screen.
      echo "ganoslal: X11 provider link complete ($(date))" >> /tmp/xrandr-init.log
      ${pkgs.xorg.xrandr}/bin/xrandr --listmonitors >> /tmp/xrandr-init.log 2>&1
    '';
  };
}
