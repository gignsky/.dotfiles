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
    # Enable SSH access to VM for easier debugging
    virtualisation.forwardPorts = [
      {
        from = "host";
        host.port = 2222;
        guest.port = 22;
      }
    ];

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
        echo "=== VM Password Setting Service Started ==="

        # Check if credentials are available
        if [ ! -d "$CREDENTIALS_DIRECTORY" ]; then
          echo "ERROR: CREDENTIALS_DIRECTORY not found!"
          exit 1
        fi

        echo "Credentials directory: $CREDENTIALS_DIRECTORY"
        ls -la "$CREDENTIALS_DIRECTORY" || true

        # Read passwords from credentials
        if [ -f "$CREDENTIALS_DIRECTORY/gig-password" ]; then
          GIG_PASS=$(cat $CREDENTIALS_DIRECTORY/gig-password)
          echo "✓ Read gig-password (length: ''${#GIG_PASS})"
        else
          echo "ERROR: gig-password credential not found!"
          exit 1
        fi

        if [ -f "$CREDENTIALS_DIRECTORY/root-password" ]; then
          ROOT_PASS=$(cat $CREDENTIALS_DIRECTORY/root-password)
          echo "✓ Read root-password (length: ''${#ROOT_PASS})"
        else
          echo "ERROR: root-password credential not found!"
          exit 1
        fi

        # Detect password format and set passwords
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
        echo "=== VM Password Setting Service Completed ==="
      '';
    };

    # TEMPORARY: Set known password for debugging
    # Remove these once credential system is working
    users.users.gig = {
      hashedPasswordFile = lib.mkForce null;
      password = lib.mkForce "nixos"; # Temporary debugging password
    };

    users.users.root = {
      hashedPasswordFile = lib.mkForce null;
      password = lib.mkForce "nixos"; # Temporary debugging password
    };
  };
}
