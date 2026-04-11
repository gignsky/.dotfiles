{
  config,
  lib,
  pkgs,
  ...
}:
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

    # Create early boot service to set passwords from credentials
    systemd.services.vm-set-passwords = {
      description = "Set user passwords from VM credentials";
      wantedBy = [ "multi-user.target" ];
      before = [
        "getty@.service"
        "display-manager.service"
      ];
      after = [ "systemd-tmpfiles-setup.service" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        LoadCredential = [
          "gig-password"
          "root-password"
        ];
      };

      script = ''
        # Read passwords from credentials
        GIG_PASS=$(cat $CREDENTIALS_DIRECTORY/gig-password)
        ROOT_PASS=$(cat $CREDENTIALS_DIRECTORY/root-password)

        # Debug: Log password format detection
        echo "Checking password format..."
        if echo "$GIG_PASS" | head -c 3 | grep -q '^\$'; then
          echo "✓ Passwords appear to be hashed (using chpasswd -e)"
          echo "gig:$GIG_PASS" | ${pkgs.shadow}/bin/chpasswd -e
          echo "root:$ROOT_PASS" | ${pkgs.shadow}/bin/chpasswd -e
        else
          echo "⚠ Passwords appear to be plaintext (using chpasswd without -e)"
          echo "gig:$GIG_PASS" | ${pkgs.shadow}/bin/chpasswd
          echo "root:$ROOT_PASS" | ${pkgs.shadow}/bin/chpasswd
        fi

        echo "✓ VM user passwords set from credentials"
      '';
    };

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
