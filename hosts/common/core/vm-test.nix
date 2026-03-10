{ pkgs, lib, ... }:
{
  # Enhanced NixOS VM test with additional checks for services, users, networking, and ports.
  system.build.vmTest = pkgs.testers.nixosTest {
    name = "system-test";

    nodes.machine =
      { pkgs, ... }:
      {
        virtualisation = {
          # VM-specific configuration - Aggressive performance settings
          memorySize = 8192; # 8GB for fast test execution
          cores = 6; # 6 cores for parallel operations
          diskSize = 10240;
        }; # 10GB disk space

        # Basic system configuration
        system.stateVersion = "25.05";

        # Enable SSH for testing
        services.openssh.enable = true;

        # Basic nix configuration
        nix.settings.experimental-features = "nix-command flakes";

        # Enable common shells
        programs.zsh.enable = true;

        # Create test users
        users.users.gig = {
          isNormalUser = true;
          extraGroups = [
            "wheel"
            "networkmanager"
          ];
          shell = pkgs.zsh;
          createHome = true;
          home = "/home/gig";
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILLFnhQHbSUOmhOxjCCVaMNPzDFXbWoFbLCxjz9x0uuI" # test key
          ];
        };

        # Enable sudo for wheel group
        security.sudo.wheelNeedsPassword = false;

        # Basic networking
        networking.hostName = "test-vm";
        networking.networkmanager.enable = true;

        # Locale settings
        time.timeZone = "America/New_York";
        i18n.defaultLocale = "en_US.UTF-8";

        # Boot configuration for VM
        boot.loader.grub.enable = lib.mkForce false;
      };

    testScript = ''
      start_all()

      # 1. Check for running sshd service
      machine.wait_for_unit("sshd.service")
      machine.succeed("systemctl is-active sshd")

      # 2. Validate user accounts
      machine.succeed("id gig")
      machine.succeed("su - gig -c 'echo login-success'")

      # 3. Test local network connectivity (instead of external)
      machine.succeed("ping -c 1 127.0.0.1")

      # 4. Check for open port 22 (SSH)
      machine.succeed("ss -tln | grep ':22 '")

      # 5. Validate critical services are running
      machine.wait_for_unit("multi-user.target")

      # 6. Check that home directories were created
      machine.succeed("test -d /home/gig")

      # 7. Validate system configuration
      machine.succeed("nix-env --version")
      machine.succeed("systemctl --version")

      # 8. Test that nix flakes are enabled
      machine.succeed("nix flake --version")

      # 9. Check disk space and basic system health
      machine.succeed("df -h")
      machine.succeed("free -h")

      # 10. Test that zsh is available
      machine.succeed("zsh --version")

      # 11. Optional: Test OpenCode if available (home-manager user package)
      print("Checking for OpenCode installation...")
      opencode_available = machine.succeed(
          "su - gig -c 'which opencode' 2>/dev/null || echo 'not-found'"
      ).strip()

      if "not-found" not in opencode_available:
          print("OpenCode detected! Running integration tests...")
          
          # 11a. Verify OpenCode can show version
          machine.succeed("su - gig -c 'opencode --version'")
          print("  ✓ OpenCode version check passed")
          
          # 11b. Check that OpenCode config exists
          machine.succeed("su - gig -c 'test -f ~/.config/opencode/config.json'")
          print("  ✓ OpenCode config.json exists")
          
          # 11c. Validate JSON structure of config
          machine.succeed("su - gig -c 'jq . ~/.config/opencode/config.json > /dev/null'")
          print("  ✓ OpenCode config.json is valid JSON")
          
          # 11d. Check for MCP configuration section
          mcp_configured = machine.succeed(
              "su - gig -c 'jq \".mcp | length\" ~/.config/opencode/config.json'"
          ).strip()
          if int(mcp_configured) > 0:
              print(f"  ✓ Found {mcp_configured} MCP server(s) configured")
              
              # 11e. List configured MCP servers
              mcp_servers = machine.succeed(
                  "su - gig -c 'jq -r \".mcp | keys[]\" ~/.config/opencode/config.json'"
              ).strip().split("\n")
              print("  ✓ Configured MCP servers:")
              for server in mcp_servers:
                  print(f"    - {server}")
          else:
              print("  ⚠ No MCP servers configured (this may be intentional)")
          
          print("  ✓ All OpenCode integration tests passed!")
      else:
          print("  ℹ OpenCode not installed on this host (skipping tests)")

      print("\n===== All VM tests passed successfully! =====")
    '';
  };
}
