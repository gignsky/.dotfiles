#
# This file defines overlays/custom modifications to upstream packages
#

{ inputs, ... }:
{
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs { pkgs = final; };

  # # This one contains whatever you want to overlay
  # # You can change versions, add patches, set compilation flags, anything really.
  # # https://wiki.nixos.org/wiki/Overlays
  # modifications = final: prev: {
  #   # example = prev.example.overrideAttrs (oldAttrs: let ... in {
  #   # ...
  #   # });
  # };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable =
      let
        inherit (final.stdenv.hostPlatform) system;
      in
      (import inputs.nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      }).extend
        # `import <gigpkgs> {}` goes through gigpkgs's default.nix shim, which doesn't
        # pass `inputs` to pkgs/inputs/*, so input-backed packages (roll-flow) are
        # broken there. Re-splice them from the flake `packages` output, which does.
        # (`.extend` so this lands after the shim's own overlay.)
        (_: _: { inherit (inputs.nixpkgs-unstable.packages.${system}) roll-flow; });
  };
  # local-packages = final: _prev: {
  #   unstable = import inputs.nixpkgs-local {
  #     inherit (final.stdenv.hostPlatform) system;
  #     config.allowUnfree = true;
  #   };
  # };

  # # wrap packages overlay example
  # wrap-packages = final: _prev: {
  #   wrap = {
  #     recursive-tarballs = inputs.wrap.packages.${final.stdenv.hostPlatform.system}.default;
  #   };
  # };
}
