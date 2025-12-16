# Bat Configuration - A modern replacement for cat with syntax highlighting
# https://github.com/sharkdp/bat
_:

{
  programs.bat = {
    enable = true;

    config = {
      # Always use paging for output longer than terminal height
      paging = "auto";

      # Use less as the pager with these options:
      # -R: Raw control characters (for colors)
      # -F: Quit if entire file fits on one screen
      # -X: Don't send termcap initialization strings
      # -i: Ignore case in searches
      # -g: Only highlight first match of search
      pager = "less -RFXig";

      # Show line numbers
      style = "numbers,changes,header";

      # Set the theme
      theme = "TwoDark";

      # Enable color output even when piped
      color = "auto";

      # Show non-printable characters
      show-all = false;

      # Wrap long lines
      wrap = "auto";
    };

    # Add custom themes or syntaxes if needed
    themes = { };
    syntaxes = { };
  };

  # Set environment variables for bat
  home.sessionVariables = {
    # Force bat to use paging for piped input
    BAT_PAGER = "less -RFXig";
    # Ensure bat uses paging mode for piped content
    BAT_STYLE = "numbers,changes,header";
  };
}
