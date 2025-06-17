{ pkgs, ... }:
{
  # A minimal NixOS VM test that boots the system and checks for a running shell.
  system.build.vmTest = import (pkgs.path + "/nixos/tests/misc.nix") {
    inherit pkgs;
    # Optionally, you can override test configuration here if needed.
  };
}
