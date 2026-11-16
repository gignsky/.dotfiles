{ configLib, ... }:
{
  programs.direnv = {
    enable = true;
    enableNushellIntegration = false; # Disable automatic integration due to syntax issues
    enableZshIntegration = true;
    nix-direnv.enable = true;
    # Content-addressed multi-slot cache in front of nix-direnv's `use flake`,
    # so branch switches / rebuilds that touch flake.lock don't force a re-eval.
    stdlib = builtins.readFile (
      configLib.relativeToRoot "home/gig/common/resources/direnvrc-flake-cache.sh"
    );
  };

  home.file.".config/direnv/direnv.toml".source =
    configLib.relativeToRoot "home/gig/common/resources/direnv.toml";
}
