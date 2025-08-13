# deadnix: skip-file
# NOTE: Home Manager modules must use { config, pkgs, ... } even if unused.
#       Ignore deadnix warnings about unused arguments here.
_: {
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    # presets = [
    #   "nerd-font-symbols"
    #   "bracketed-segments"
    # ];
    enableNushellIntegration = true;
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

      # Shell module to display shell name when not using default nushell
      shell = {
        disabled = false;
        format = "[$indicator]($style) ";
        style = "cyan bold";
        # Only show indicators for non-default shells
        bash_indicator = "bash";
        fish_indicator = "fish";
        zsh_indicator = "zsh";
        powershell_indicator = "pwsh";
        ion_indicator = "ion";
        elvish_indicator = "elvish";
        tcsh_indicator = "tcsh";
        nu_indicator = ""; # Don't show indicator for nushell (default)
        xonsh_indicator = "xonsh";
        cmd_indicator = "cmd";
        unknown_indicator = "unknown";
      };
    };
  };
}
