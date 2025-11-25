{ ... }:
{
  services.displayManager.ly = {
    enable = true;
    settings = {
      # Remove auto-login as requested - manual login selection
      save = true; # Remember session choice
      animation = "none"; # Disable animations for faster boot
      hide_borders = false;
      hide_key_hints = false;

      # DISABLED: Shell configuration breaks session startup with both zsh and nushell
      # ly's shell parameter is for the shell option in ly menu, not desktop sessions
      # shell = "${pkgs.zsh}/bin/zsh";
    };
  };
}
