{ inputs, pkgs, ... }:
let
  inherit (pkgs.stdenv.hostPlatform) system;
in
{
  fonts = {
    enableDefaultPackages = false;
    fontDir.enable = true;
    packages =
      with inputs;
      with pkgs;
      [
        fancy-fonts.packages.${system}.cartograph
        fancy-fonts.packages.${system}.artifex
        fancy-fonts.packages.${system}.monolisa
        nerd-fonts.go-mono
        nerd-fonts.jetbrains-mono
        times-newer-roman
      ];
    fontconfig = {
      enable = true;
      defaultFonts = {
        # System-wide monospace: Cartograph primary, with GoMono for Nerd Font glyphs
        monospace = [
          "Cartograph CF"
          "MonoLisa Variable"
          "Artifex CF"
          "GoMono Nerd Font Mono"
          "Times Newer Roman"
        ];
        # System-wide sans-serif: Cartograph
        sansSerif = [
          "Cartograph CF"
          "MonoLisa Variable"
        ];
        # Serif: Artifex primary
        serif = [
          "Artifex CF"
          "Times Newer Roman"
          "GoMono Nerd Font Mono"
        ];
      };
    };
  };
}
