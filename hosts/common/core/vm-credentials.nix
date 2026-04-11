{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Configure VMs to access sops secrets via shared directories
  #
  # Strategy: User passwords are set to "nixos" for easy VM login.
  # Non-password secrets (cifs-creds, etc.) are mounted from the host's /run/secrets/
  # via 9p shared directories and copied during boot.
  #
  # Note: Password secrets have a race condition where they're needed during activation
  # before systemd services run, so we use static passwords instead. Other secrets
  # work fine since they're not needed during early boot.

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
    # This allows VMs to access non-password secrets (cifs-creds, etc.)
    virtualisation.sharedDirectories = {
      secrets = {
        source = "/run/secrets";
        target = "/mnt/host-secrets";
      };
    };

    # Copy non-password secrets from host during boot
    systemd.services.vm-copy-secrets = {
      description = "Copy non-password secrets from host";
      wantedBy = [ "multi-user.target" ];
      after = [ "run-vmblock\\x2dfuse.mount" ]; # After 9p mounts

      script = ''
        echo "=== VM Secrets Copy Service Started ==="

        # Create secrets directory
        mkdir -p /run/secrets

        # Copy non-password secrets from /run/secrets on host
        if [ -d /mnt/host-secrets ]; then
          echo "✓ Found host secrets directory"
          ls -la /mnt/host-secrets/ || true
          
          # Copy all secrets from host (excluding password files)
          for secret_file in /mnt/host-secrets/*; do
            if [ -f "$secret_file" ]; then
              secret_name=$(basename "$secret_file")
              # Skip password files - those use static 'nixos' password
              if [[ "$secret_name" != *"password"* ]]; then
                cp -L "$secret_file" "/run/secrets/$secret_name"
                chmod 400 "/run/secrets/$secret_name"
                chown root:root "/run/secrets/$secret_name"
                echo "✓ Copied $secret_name to /run/secrets/"
              fi
            fi
          done
        else
          echo "⚠ Host secrets directory not available"
        fi

        echo "=== VM Secrets Copy Service Completed ==="
      '';
    };

    # Set VM user passwords to 'nixos' for easy login
    # This avoids the race condition with hashedPasswordFile during activation
    users.users.gig = {
      password = lib.mkForce "nixos";
      hashedPasswordFile = lib.mkForce null;
    };

    users.users.root = {
      password = lib.mkForce "nixos";
      hashedPasswordFile = lib.mkForce null;
    };
  };
}
