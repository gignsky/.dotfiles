{ config, lib, ... }:
# Dual NVIDIA configuration for GTX 970 + RTX 3060 Ti
# No PRIME needed - both cards managed by single NVIDIA driver
# Ref: https://nixos.wiki/wiki/Nvidia
{
  nixpkgs.config.allowUnfree = lib.mkForce true;

  hardware = {
    nvidia = {
      # Use latest stable drivers (supports both Maxwell GTX 970 and Ampere RTX 3060 Ti)
      package = config.boot.kernelPackages.nvidiaPackages.stable;

      # Enable kernel modesetting (required for 535+, prevents screen tearing)
      modesetting.enable = true;

      # Use proprietary kernel modules (recommended for dual-NVIDIA setups)
      open = false;

      # Enable NVIDIA Control Panel
      nvidiaSettings = true;

      # No PRIME configuration needed - both GPUs are NVIDIA
      # The driver automatically handles multiple NVIDIA cards

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

  # Optional: Environment variables for multi-GPU optimization
  environment.variables = {
    # Force specific GPU selection if needed (uncomment for debugging)
    # __GL_SHADER_DISK_CACHE_PATH = "/tmp/nvidia-shader-cache";
    # __GL_THREADED_OPTIMIZATIONS = "1";
  };
}
