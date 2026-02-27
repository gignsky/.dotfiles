{ inputs, pkgs, ... }:
let
  inherit (pkgs.stdenv.hostPlatform) system;
in
{
  fonts = {
    enableDefaultPackages = false; # defaults to false
    fontDir.enable = true;
    packages =
      with inputs;
      with pkgs;
      [
        # fancy-fonts.packages.${system}.cartograph
        # fancy-fonts.packages.${system}.artifex
        # fancy-fonts.packages.${system}.monolisa
        nerd-fonts.go-mono
        # times-newer-roman
      ];
    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [
          # "MonoLisa Variable"
          "GoMono Nerd Font Mono"
          # "Cartograph CF"
          # "Artifex CF"
          # "Times Newer Roman"
        ];
        # sansSerif = [
        #   "MonoLisa Variable"
        # ];
        serif = [
          # "Artifex CF"
          # "Times Newer Roman"
          "GoMono Nerd Font Mono"
        ];
        # Set emoji font if needed
        # emoji = [
        #   "TEST"
        # ]
      };
    };
  };
}
