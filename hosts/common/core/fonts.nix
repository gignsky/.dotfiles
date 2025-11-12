{ inputs, system, ... }:
{
  environment.systemPackages = with inputs; [
    fancy-fonts.packages.${system}.cartograph
    fancy-fonts.packages.${system}.artifex
    fancy-fonts.packages.${system}.monolisa
  ];
}
