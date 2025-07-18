# deadnix: skip-file
# NOTE: Home Manager modules must use { config, pkgs, ... } even if unused.
#       Ignore deadnix warnings about unused arguments here.
{ config, pkgs, ... }:
{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    # presets = [
    #   "nerd-font-symbols"
    #   "bracketed-segments"
    # ];
    settings = {
      # # Get editor completions based on the config schema
      # "$schema" = 'https://starship.rs/config-schema.json';

      # Inserts a blank line between shell prompts
      add_newline = true;

      # Replace the '❯' symbol in the prompt with '➜'
      character = {
        # The name of the module we are configuring is 'character'
        success_symbol = "[>](bold green)"; # The 'success_symbol' segment is being set to '➜' with the color 'bold green'
        error_symbol = "[➜](bold red)"; # The 'error_symbol' segment is being set to '➜' with the color 'bold red'
      };

      # format = lib.concatStrings [
      #   "$line_break"
      #   "$package"
      #   "$line_break"
      #   "$character"
      # ];

      package = {
        # disabled = true; # Disable the package module, hiding it from the prompt completely
      };
    };
  };
}
