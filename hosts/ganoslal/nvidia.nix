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

      # Prime configuration - DISABLED for independent GPU operation
      prime = {
        # Disable Prime to allow both GPUs to operate independently
        # This prevents the "one giant monitor" issue and allows each GPU
        # to drive its connected monitors without interference
        sync.enable = false;

        # Bus IDs commented out since we're not using Prime
        # nvidiaBusId = "PCI:45:0:0"; # NVIDIA GPU bus ID
        # amdgpuBusId = "PCI:23:0:0"; # AMD GPU bus ID
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

  # Environment variables for independent GPU operation
  environment.variables = {
    # Enable both GPUs for OpenGL/Vulkan applications
    # Applications can choose which GPU to use explicitly
    # __GLX_VENDOR_LIBRARY_NAME = "nvidia";  # Not needed in independent mode

    # For debugging multi-GPU issues (uncomment if needed)
    # __NV_PRIME_RENDER_OFFLOAD_PROVIDER = "NVIDIA-G0";
    # __VK_LAYER_NV_optimus = "NVIDIA_only";
  };
}
