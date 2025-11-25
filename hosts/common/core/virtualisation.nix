{ lib, ... }:
{
  # Virtualisation configuration that's safe for all NixOS contexts
  # VM-specific settings (memorySize, diskSize, etc.) should be configured
  # per host or in vm-test.nix for testing scenarios

  # Enable KVM if available for better VM performance
  boot.kernelModules = lib.mkDefault [
    "kvm-intel"
    "kvm-amd"
  ];

  # Ensure virtualisation is available
  virtualisation = {
    # Docker configuration - safe for all contexts
    docker.enable = lib.mkDefault false;

    # Podman configuration - safe for all contexts
    podman.enable = lib.mkDefault false;
  };
}
