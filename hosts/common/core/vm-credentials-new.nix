{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Configure VMs to access sops secrets via shared directory
  # This avoids the build-time vs runtime issue with virtualisation.credentials

  virtualisation.vmVariant = {
    # Enable SSH access to VM for easier debugging
    virtualisation.forwardPorts = [
      {
        from = "host";
        host.port = 2222;
        guest.port = 22;
      }
    ];

    # Share the host's /run/secrets directory with the VM
    # This way VMs can access decrypted sops secrets from the running host
    virtualisation.sharedDirectories = {
      secrets = {
        source = "/run/secrets";
        target = "/mnt/host-secrets";
      };
    };

    # Create early boot service to copy secrets from shared mount
    systemd.services.vm-copy-secrets = {
      description = "Copy secrets from host shared directory";
      wantedBy = [ "multi-user.target" ];
      before = [
        "getty@.service"
        "display-manager.service"
      ];
      after = [ "run-vmblock\\x2dfuse.mount" ]; # After 9p mounts

      script = ''
        echo "=== VM Secrets Copy Service Started ==="

        # Create secrets directory
        mkdir -p /run/secrets

        # Copy secrets from host mount (if available)
        if [ -d /mnt/host-secrets ]; then
          echo "✓ Found host secrets directory"
          
          # Copy password files
          for secret in gig-password root-password cifs-creds; do
            if [ -f "/mnt/host-secrets/$secret" ]; then
              cp -L "/mnt/host-secrets/$secret" "/run/secrets/$secret"
              chmod 400 "/run/secrets/$secret"
              chown root:root "/run/secrets/$secret"
              echo "✓ Copied $secret"
            else
              echo "⚠ Secret $secret not found in host"
            fi
          done
          
          echo "✓ Secrets copied successfully"
        else
          echo "⚠ Host secrets directory not available - using fallback passwords"
          # Fallback: create test password files
          echo "nixos" > /run/secrets/gig-password
          echo "nixos" > /run/secrets/root-password
          chmod 400 /run/secrets/*
        fi

        echo "=== VM Secrets Copy Service Completed ==="
      '';
    };

    # Users will read passwords from /run/secrets (same as physical host)
    # No need to override hashedPasswordFile - it already points to /run/secrets
    # The vm-copy-secrets service ensures those files exist
  };
}
