{
  outputs,
  nixpkgs,
  ...
}:
let
  # Fast, essential configuration validation only for `nix flake check`

  # Home Manager activation package checks
  homeManagerChecks = nixpkgs.lib.mapAttrs' (name: cfg: {
    name = "homeManager-${name}";
    value = cfg.activationPackage;
  }) outputs.homeConfigurations;

  # Basic NixOS configuration builds (without resource-intensive VM tests)
  nixosConfigChecks = nixpkgs.lib.mapAttrs' (name: config: {
    name = "nixosConfig-${name}";
    value = config.config.system.build.toplevel;
  }) outputs.nixosConfigurations;
in
# Merge all checks into a flat attribute set
homeManagerChecks // nixosConfigChecks
