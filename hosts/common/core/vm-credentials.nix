{ config, lib, ... }:
{
  options.virtualisation.credentials = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          source = lib.mkOption { type = lib.types.path; };
        };
      }
    );
  };

  config = lib.mkIf (config.virtualisation ? qemu) {
    # Pass all sops secrets as VM credentials
    virtualisation.credentials = lib.mapAttrs' (
      name: secret:
      lib.nameValuePair name {
        # Use the decrypted secret path from host
        source = secret.path;
      }
    ) config.sops.secrets;

    # # Override user password configuration for VMs
    # # We need to read password from systemd credentials instead of sops
    # users.users.gig = {
    #   # In VMs, we'll handle password differently - see Step 3
    #   hashedPasswordFile = lib.mkForce null;
    # };
    #
    # users.users.root = {
    #   hashedPasswordFile = lib.mkForce null;
    # };
  };
}
