{ configLib, ... }:
{
  programs.direnv = {
    enable = true;
    enableNushellIntegration = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  home.file.".config/direnv/direnv.toml".source = configLib.relativeToRoot "home/gig/common/resources/direnv.toml";
}