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

      # Prime configuration - EXPLICITLY DISABLED for independent GPU operation
      # The common-gpu-nvidia nixos-hardware module enables Prime by default,
      # so we need to explicitly disable it for independent dual-GPU operation
      prime = {
        offload.enable = lib.mkForce false;
        sync.enable = lib.mkForce false;
        # Provide bus IDs to satisfy the assertion, but with Prime disabled they won't be used
        nvidiaBusId = "PCI:45:0:0";
        amdgpuBusId = "PCI:23:0:0";
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
