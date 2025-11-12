{ inputs, pkgs, ... }:
let
  inherit (pkgs.stdenv.hostPlatform) system;
in
{
  fonts.packages =
    with inputs;
    with pkgs;
    [
      fancy-fonts.packages.${system}.cartograph
      fancy-fonts.packages.${system}.artifex
      fancy-fonts.packages.${system}.monolisa
      nerd-fonts.go-mono
    ];
}
