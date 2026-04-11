{ config, lib, ... }:
{
  # Configure credentials for VMs using virtualisation.vmVariant
  # This configuration only applies when building VMs with nixos-rebuild build-vm

  virtualisation.vmVariant = {
    # Pass all sops secrets as VM credentials
    virtualisation.credentials = lib.mapAttrs' (
      name: secret:
      lib.nameValuePair name {
        # Use the decrypted secret path from host
        source = secret.path;
      }
    ) config.sops.secrets;

    # Override user password configuration for VMs
    # We need to read password from systemd credentials instead of sops
    users.users.gig = {
      hashedPasswordFile = lib.mkForce null;
    };

    users.users.root = {
      hashedPasswordFile = lib.mkForce null;
    };
  };
}
