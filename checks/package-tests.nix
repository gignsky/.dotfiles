{ lib, pkgs }:
let
  packageBuilds = lib.mapAttrs' (name: pkg: {
    name = "build-${name}";
    value = pkg;
  }) (import ../pkgs { inherit pkgs; });
in
packageBuilds
