{ inputs, pkgs, ... }:
let
  inherit (pkgs.stdenv.hostPlatform) system;
in
{
  fonts = {
    enableDefaultPackages = false; # Disabled - using surgical font selection
    enableGhostscriptFonts = true;
    fontDir = {
      enable = true;
      decompressFonts = true;
    };
    packages =
      with inputs;
      with pkgs;
      [
        # Lord Gig's fancy fonts
        fancy-fonts.packages.${system}.cartograph
        fancy-fonts.packages.${system}.artifex
        fancy-fonts.packages.${system}.monolisa
        nerd-fonts.go-mono
        nerd-fonts.jetbrains-mono
        times-newer-roman

        # Essential icon/symbol fonts (replaces enableDefaultPackages)
        noto-fonts-color-emoji # Emoji support
        dejavu_fonts # Broad Unicode + symbols
        unifont # Rare glyph coverage
        liberation_ttf # Web compatibility (Arial/Times fallback)
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
        # System-wide monospace: Cartograph primary, with comprehensive fallbacks
        monospace = [
          "MonoLisa Variable"
          "Cartograph CF"
          "Artifex CF"
          "GoMono Nerd Font Mono" # Nerd Font icons
          "JetBrainsMono Nerd Font Mono" # Additional icon coverage
          "DejaVu Sans Mono" # Unicode fallback
          "Noto Color Emoji" # Emoji support
        ];
        # System-wide sans-serif: Cartograph with icon/symbol fallbacks
        sansSerif = [
          "Cartograph CF"
          "MonoLisa Variable"
          "DejaVu Sans" # Unicode fallback
          "Noto Color Emoji" # Emoji support
        ];
        # Serif: Artifex primary with fallbacks
        serif = [
          "Artifex CF"
          "Times Newer Roman"
          "DejaVu Serif" # Unicode fallback
          "Noto Color Emoji" # Emoji support
        ];
        # Explicit emoji preference
        emoji = [
          "Noto Color Emoji"
        ];
      };
    };
  };
}
