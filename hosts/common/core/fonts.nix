{ inputs, pkgs, ... }:
let
  inherit (pkgs.stdenv.hostPlatform) system;
in
{
  environment.systemPackages = with inputs; [
    fancy-fonts.packages.${system}.cartograph
    fancy-fonts.packages.${system}.artifex
    fancy-fonts.packages.${system}.monolisa
  ];
}
