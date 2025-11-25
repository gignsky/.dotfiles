{
  inputs,
  outputs,
  nixpkgs,
  configVars,
  configLib,
  system,
  pkgs,
  assertAllHostsHaveVmTest,
  ...
}:
let
  preCommitHooks = import ./pre-commit-hooks.nix {
    inherit inputs system;
  };
  coreChecks = import ./checks.nix {
    inherit
      inputs
      outputs
      nixpkgs
      configVars
      configLib
      system
      ;
  };
in
{
  # Resource-intensive development checks for comprehensive validation

  # VM tests for NixOS configurations (resource-intensive)
  nixosTests =
    assert assertAllHostsHaveVmTest outputs.nixosConfigurations;
    nixpkgs.lib.filterAttrs (_: v: v != null) (
      nixpkgs.lib.mapAttrs' (name: config: {
        name = "nixosTest-${name}";
        value = config.config.system.build.vmTest or null;
      }) outputs.nixosConfigurations
    );

  # Custom package build tests
  packageBuilds = nixpkgs.lib.mapAttrs' (name: pkg: {
    name = "build-${name}";
    value = pkg;
  }) (import ../pkgs { inherit pkgs; });

  # Pre-commit hooks check (with hardware config exclusions)
  pre-commit-check-dev = preCommitHooks.mkPreCommitCheck ./../.;
}
# Include all core checks as well - this creates a comprehensive check set
// coreChecks
