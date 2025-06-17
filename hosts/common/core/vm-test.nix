{ pkgs, ... }:
{
  # Enhanced NixOS VM test with additional checks for services, users, networking, and ports.
  system.build.vmTest = import (pkgs.path + "/nixos/tests/misc.nix") {
    inherit pkgs;
    testScript = ''
      start_all()
      # 1. Check for running sshd service
      machine.wait_for_unit("sshd.service")
      machine.succeed("systemctl is-active sshd")

      # 2. Validate user account 'gig'
      machine.succeed("id gig")
      machine.succeed("su - gig -c 'echo login-success'")

      # 3. Test network connectivity
      machine.succeed("ping -c 1 8.8.8.8")

      # 4. Check for open port 22 (SSH)
      machine.succeed("ss -tln | grep ':22 '")
    '';
  };
}
