{ pkgs, ... }:
{
  services.displayManager.ly = {
    enable = true;
    settings = {
      # Remove auto-login as requested - manual login selection
      save = true; # Remember session choice
      animation = "none"; # Disable animations for faster boot
      hide_borders = false;
      hide_key_hints = false;

      # FIX: Shell session command - use zsh which user has configured
      shell = "${pkgs.zsh}/bin/zsh";
    };
  };
}
