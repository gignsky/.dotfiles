{ inputs, pkgs, ... }:
let
  inherit (pkgs.stdenv.hostPlatform) system;
in
{
  fonts = {
    enableDefaultPackages = false;
    enableGhostscriptFonts = true;
    fontDir = {
      enable = true;
      decompressFonts = true;
    };
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
      allowBitmaps = true;
      allowType1 = true;
      antialias = true;
      cache32Bit = true;
      includeUserConf = true;
      useEmbeddedBitmaps = true;
      defaultFonts = {
        # System-wide monospace: Cartograph primary, with GoMono for Nerd Font glyphs
        monospace = [
          "MonoLisa Variable"
          "Cartograph CF"
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
