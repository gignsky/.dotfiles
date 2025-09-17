{ lib, configLib, ... }:
{
  programs.direnv = {
    enable = true;
    enableNushellIntegration = false; # Disable automatic integration due to syntax issues
    enableZshIntegration = true;
    nix-direnv.enable = true;
    configToml = lib.readFile configLib.relativeToRoot "home/gig/common/resources/direnv.toml";
  };
}
