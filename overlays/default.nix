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
  # be accessible through 'pkgs.unstable'.
  #
  # The `.extend` re-applies gigpkgs' own overlay (built with real flake inputs)
  # on top of the plain import, which otherwise can't resolve gigpkgs' custom
  # packages (roll-flow, gigvim, ...) under `pkgs.unstable.*`.
  unstable-packages = final: _prev: {
    unstable =
      (import inputs.nixpkgs-unstable {
        inherit (final.stdenv.hostPlatform) system;
        config.allowUnfree = true;
      }).extend
        inputs.nixpkgs-unstable.overlays.default;
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
  #     recursive-tarballs = inputs.wrap.packages.${final.system}.default;
  #   };
  # };
}
