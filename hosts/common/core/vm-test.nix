{ pkgs, lib, ... }:
{
  # Enhanced NixOS VM test with additional checks for services, users, networking, and ports.
  system.build.vmTest = pkgs.nixosTest {
    name = "system-test";

    nodes.machine = { pkgs, ... }: {
      # VM-specific configuration
      virtualisation.memorySize = 2048;
      virtualisation.cores = 2;

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
        extraGroups = [ "wheel" "networkmanager" ];
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
      
      print("All VM tests passed successfully!")
    '';
  };
}
