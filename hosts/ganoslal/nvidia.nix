{ config, lib, ... }:
# Dual-NVIDIA GPU configuration for multi-monitor setup
# Primary: NVIDIA RTX 3060 Ti (PCI:2d:0:0) - DP-1, DP-2, HDMI-0
# Secondary: NVIDIA GTX 970 (PCI:23:0:0) - HDMI-A-1 (top center display)
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

      # NOTE: PRIME is for hybrid laptop configurations (integrated + discrete GPU)
      # For dual discrete NVIDIA GPUs, we don't use PRIME at all
      # Instead, both GPUs are managed by the nvidia driver as separate devices

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
    # The nvidia driver will automatically detect both cards
    # and expose all outputs through a single unified X screen
    screenSection = ''
      Option         "metamodes" "nvidia-auto-select +0+0"
      Option         "AllowEmptyInitialConfiguration" "True"
      Option         "ConnectedMonitor" "DFP"
    '';

    # Enable RandR for dynamic multi-monitor configuration
    deviceSection = ''
      Option "AllowExternalGpus" "True"
    '';
  };

  # Optional: Environment variables for debugging/optimization
  environment.variables = {
    # Force applications to use NVIDIA GPU
    # __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };
}
