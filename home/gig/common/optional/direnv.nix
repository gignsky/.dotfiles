{ configLib, ... }:
{
  programs.direnv = {
    enable = true;
    enableNushellIntegration = false; # Disable automatic integration due to syntax issues
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  home.file.".config/direnv/direnv.toml".source =
    configLib.relativeToRoot "home/gig/common/resources/direnv.toml";
}
