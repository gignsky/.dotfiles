{ inputs, pkgs, ... }:
let
  inherit (pkgs.stdenv.hostPlatform) system;
in
{
  fonts = {
    packages =
      with inputs;
      with pkgs;
      [
        fancy-fonts.packages.${system}.cartograph
        fancy-fonts.packages.${system}.artifex
        fancy-fonts.packages.${system}.monolisa
        nerd-fonts.go-mono
        times-newer-roman
      ];
    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [
          "Cartograph CF"
          "Artifex CF"
          "Monolisa Variable"
          "GoMono Nerd Font Mono"
          "Times Newer Roman"
        ];
        sansSerif = [
          "Monolisa Variable"
        ];
        serif = [
          "Artifex CF"
          "Times Newer Roman"
        ];
        # Set emoji font if needed
        # emoji = [
        #   "TEST"
        # ]
      };
    };
  };
}
