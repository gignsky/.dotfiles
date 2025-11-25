{ config, lib, ... }:
# Modern NVIDIA Prime configuration for dual-GPU setup
# NVIDIA primary + AMD secondary with 6-monitor support
# Ref: https://nixos.wiki/wiki/Nvidia
{
  nixpkgs.config.allowUnfree = lib.mkForce true;

  hardware = {
    nvidia = {
      # Use latest stable drivers (535+ with modern features)
      package = config.boot.kernelPackages.nvidiaPackages.stable;

      # Enable kernel modesetting (required for 535+, prevents screen tearing)
      modesetting.enable = true;

      # Use proprietary kernel modules (recommended for multi-GPU setups)
      # Set to true for RTX/GTX 16xx series with driver 560+ if you want open-source
      open = false;

      # Enable NVIDIA Control Panel
      nvidiaSettings = true;

      # Prime configuration - NVIDIA as primary, AMD as secondary
      prime = {
        # Sync mode: NVIDIA always on, handles all rendering and outputs
        sync.enable = true;

        # Bus IDs - verify these match your hardware with 'lspci'
        nvidiaBusId = "PCI:45:0:0"; # NVIDIA GPU bus ID
        amdgpuBusId = "PCI:23:0:0"; # AMD GPU bus ID
      };

      # Enable power management for better stability
      powerManagement = {
        enable = lib.mkDefault true;
        # finegrained = false;  # Only for offload mode, not sync
      };
    };

    # Graphics subsystem configuration
    graphics = {
      enable = true;
      enable32Bit = true; # Support for 32-bit applications/games
    };
  };

  # Optional: Environment variables for debugging/optimization
  environment.variables = {
    # Force applications to use NVIDIA GPU (not needed in sync mode but useful for debugging)
    # __GLX_VENDOR_LIBRARY_NAME = "nvidia";

    # For debugging PRIME issues (uncomment if needed)
    # __NV_PRIME_RENDER_OFFLOAD_PROVIDER = "NVIDIA-G0";
    # __VK_LAYER_NV_optimus = "NVIDIA_only";
  };
}
