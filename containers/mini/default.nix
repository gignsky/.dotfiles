# Mini Container Module
# Default exports for a minimal NixOS base container. Ported from dot-spacedock.
# Not wired into flake outputs by default — see containers/README.md (requires
# the `nixos-generators` flake input).

{
  inputs,
  lib,
  system,
}:

{
  nixosConfigurations.mini = inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = {
      inherit inputs lib system;
      configVars = import ../../vars { inherit inputs lib; };
      configLib = import ../../lib { inherit lib; };
      outputs = {
        overlays = import ../../overlays { inherit inputs; };
      };
      inherit (inputs) nixpkgs;
    };
    modules = [
      ./config.nix
      # Apply minimal profile for size reduction
      "${inputs.nixpkgs}/nixos/modules/profiles/minimal.nix"
    ];
  };

  packages = import ./packages.nix { inherit inputs lib system; };
}
