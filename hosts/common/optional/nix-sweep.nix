{ inputs, pkgs, ... }:
let
  inherit (pkgs.stdenv.hostPlatform) system;
in
{
  environment.systemPackages = with inputs; [
    nix-sweep.packages.${system}.default
  ];
}
