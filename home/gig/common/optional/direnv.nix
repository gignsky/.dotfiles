_: {
  programs.direnv = {
    enable = true;
    enableNushellIntegration = false; # Disable automatic integration due to syntax issues
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  home.file.".config/direnv/direnv.toml".source = "../resources/direnv.toml";
}
