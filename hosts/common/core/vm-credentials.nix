{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Configure VMs to access sops secrets via shared directories
  #
  # Background: sops-nix decrypts secrets at runtime on the physical host, but
  # `nixos-rebuild build-vm` builds VMs at build-time when secrets don't exist yet.
  # The virtualisation.credentials option (available in nixpkgs-unstable) requires
  # file paths at build-time, so it can't work with sops-nix runtime secrets.
  #
  # Solution: Use virtualisation.sharedDirectories to mount the host's /run/secrets*
  # directories into the VM via 9p, then copy them during VM boot.
  #
  # Note: sops-nix creates TWO secret directories on the host:
  #   - /run/secrets-for-users/ - secrets with neededForUsers = true (passwords)
  #   - /run/secrets/ - regular secrets (cifs-creds, etc)

  virtualisation.vmVariant = {
    # Enable SSH access to VM for easier debugging
    virtualisation.forwardPorts = [
      {
        from = "host";
        host.port = 2222;
        guest.port = 22;
      }
    ];

    # Share the host's secrets directories with the VM
    # This way VMs can access decrypted sops secrets from the running host
    # Note: sops-nix separates secrets into two directories:
    #   - /run/secrets-for-users/ - secrets with neededForUsers = true
    #   - /run/secrets/ - regular secrets
    virtualisation.sharedDirectories = {
      secrets-for-users = {
        source = "/run/secrets-for-users";
        target = "/mnt/host-secrets-for-users";
      };
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

        # Create secrets directories (VM expects /run/secrets-for-users/ for passwords)
        mkdir -p /run/secrets-for-users
        mkdir -p /run/secrets

        # Copy password secrets from host's /run/secrets-for-users to VM's /run/secrets-for-users
        if [ -d /mnt/host-secrets-for-users ]; then
          echo "✓ Found host secrets-for-users directory"
          ls -la /mnt/host-secrets-for-users/ || true
          
          # Copy password files (gig-password, root-password)
          for secret in gig-password root-password; do
            if [ -f "/mnt/host-secrets-for-users/$secret" ]; then
              cp -L "/mnt/host-secrets-for-users/$secret" "/run/secrets-for-users/$secret"
              chmod 400 "/run/secrets-for-users/$secret"
              chown root:root "/run/secrets-for-users/$secret"
              
              # Debug: show length only (don't preview password hashes)
              SECRET_LEN=$(wc -c < "/run/secrets-for-users/$secret")
              echo "✓ Copied $secret to /run/secrets-for-users/ (length: $SECRET_LEN bytes)"
            else
              echo "⚠ Secret $secret not found in host secrets-for-users"
            fi
          done
        else
          echo "⚠ Host secrets-for-users directory not available"
        fi

        # Copy regular secrets from /run/secrets on host
        if [ -d /mnt/host-secrets ]; then
          echo "✓ Found host secrets directory"
          ls -la /mnt/host-secrets/ || true
          
          # Copy non-password secrets (e.g., cifs-creds)
          for secret in cifs-creds; do
            if [ -f "/mnt/host-secrets/$secret" ]; then
              cp -L "/mnt/host-secrets/$secret" "/run/secrets/$secret"
              chmod 400 "/run/secrets/$secret"
              chown root:root "/run/secrets/$secret"
              echo "✓ Copied $secret to /run/secrets/"
            else
              echo "⚠ Secret $secret not found in host secrets"
            fi
          done
        else
          echo "⚠ Host secrets directory not available"
        fi

        # Fallback: if no secrets were copied, use test password
        if [ ! -f /run/secrets-for-users/gig-password ]; then
          echo "⚠ No secrets copied - using fallback 'nixos' password"
          echo "nixos" > /run/secrets-for-users/gig-password
          echo "nixos" > /run/secrets-for-users/root-password
          chmod 400 /run/secrets-for-users/*
        fi

        echo "=== VM Secrets Copy Service Completed ==="
      '';
    };

    # VM users should now use hashedPasswordFile from sops secrets
    # The vm-copy-secrets service copies them from the host's /run/secrets-for-users/
  };
}
