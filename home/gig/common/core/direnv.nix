{ lib, configLib, ... }:
let
  direnvTomlPath = configLib.relativeToRoot "home/gig/common/resources/direnv.toml";
in

{
  programs.direnv = {
    enable = true;
    enableNushellIntegration = false; # Disable automatic integration due to syntax issues
    enableZshIntegration = true;
    nix-direnv.enable = true;
    configToml = lib.readFile direnvTomlPath;
  };
}
