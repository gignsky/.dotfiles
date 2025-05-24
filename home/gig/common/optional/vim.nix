{ inputs, pkgs, ... }:

{
  home.packages = [
    # inputs.neve.packages.${pkgs.system}.default
    pkgs.lunarvim
  ];
}
