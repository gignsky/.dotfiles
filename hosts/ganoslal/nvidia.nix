{ config, lib, ... }:
# Ref. https://nixos.wiki/wiki/Nvidia
{
  nixpkgs.config.allowUnfree = lib.mkForce true;

  # Ensure NVIDIA loads first and is primary
  boot.kernelModules = [ "nvidia" ];
  boot.kernelParams = [
    # Force NVIDIA as primary GPU
    "nvidia-drm.modeset=1"
    # Ensure proper AMD GPU support for older cards
    "radeon.si_support=0"
    "amdgpu.si_support=1"
  ];

  hardware = {
    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      modesetting.enable = true;
      powerManagement.enable = true;
      open = false;
      nvidiaSettings = true;

      # Configure PRIME for dual GPU setup with NVIDIA primary
      prime = {
        # Use offload mode instead of sync to allow NVIDIA primary
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
        nvidiaBusId = "PCI:45:0:0";
        amdgpuBusId = "PCI:23:0:0";
      };
    };

    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  # Configure PipeWire for better audio support including SPDIF
  security.rtkit.enable = true;
  services = {
    # Enable SPDIF/optical audio output
    pulseaudio.enable = false; # We'll use PipeWire instead
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;

      # Enable JACK support for professional audio
      jack.enable = true;

      # Configure audio devices including SPDIF
      extraConfig.pipewire."99-spdif" = {
        "context.properties" = {
          "default.clock.rate" = 48000;
          "default.clock.quantum" = 1024;
          "default.clock.min-quantum" = 32;
          "default.clock.max-quantum" = 8192;
        };
      };
    };
  };

  # Additional audio configuration for SPDIF optical output
  environment.etc."modprobe.d/alsa-base.conf".text = ''
    # Enable SPDIF output by default
    options snd-hda-intel enable_msi=1
    options snd-hda-intel model=auto
  '';
}
