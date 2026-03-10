{
  self,
  pkgs,
  lib,
}:
let
  nixosTests = import ./nixos-tests.nix { inherit lib self; };
  packageTests = import ./package-tests.nix { inherit lib pkgs; };
  openCodeTests = import ./opencode-tests.nix { inherit lib self pkgs; };
  # homeManagerTests = import ./home-manager-tests.nix { inherit lib self; };
in
# Merge all test attributes into a single flat set
nixosTests // packageTests // openCodeTests # // homeManagerTests
