# Vim-keybinding File Managers Collection
# A comprehensive collection of terminal file managers that use vim keybindings
# All are included for evaluation - enable/disable individual managers as needed

{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # ranger - The most popular vim-like file manager
    # Features:
    # - Default vim keybindings (hjkl navigation, / search, yy copy, dd cut)
    # - Three-pane layout with file preview
    # - Python-based with extensive customization
    # - Preview support for files, images, PDFs in terminal
    # - Rich plugin ecosystem and theming support
    # Usage: Just run 'ranger' - vim keybindings work out of the box
    ranger

    # lf (List Files) - Lightweight and fast vim-style file manager
    # Features:
    # - Pure vim keybindings designed from ground up
    # - Written in Go for speed and minimal resource usage
    # - Highly scriptable and easy to extend
    # - Similar workflow to ranger but faster startup
    # - Clean, minimal interface
    # Usage: Run 'lf' - all standard vim navigation applies
    lf

    # vifm - Dual-pane file manager with comprehensive vim keybindings
    # Features:
    # - True vim keybindings with command mode (:commands)
    # - Dual-pane interface similar to mc layout
    # - Most vim-like experience of all file managers
    # - Extensive customization and vim-style configuration
    # - Support for vim-style marks, registers, and macros
    # Usage: Run 'vifm' - closest to actual vim editor experience
    vifm

    # nnn - Fast file manager (vim keybindings configurable)
    # Features:
    # - Not vim by default, but can be configured for vim-style navigation
    # - Extremely fast and optimized for performance
    # - Extensive plugin ecosystem and customization
    # - Multiple selection modes and powerful file operations
    # - Minimal resource usage
    # Usage: Run 'nnn' - may need configuration for full vim experience
    nnn

    # Additional utilities that complement vim file managers:

    # fzf - Fuzzy finder that works great with vim-style file managers
    # Integrates well with ranger, lf, and vifm for file searching
    fzf

    # bat - Better 'cat' with syntax highlighting
    # Perfect for file previews in vim file managers
    bat

    # eza - Better 'ls' with colors and git integration
    # Enhanced directory listings for file manager previews
    eza

    # fd - Fast 'find' alternative
    # Faster file searching for vim file managers
    fd
  ];

  # Optional: Basic configuration suggestions
  # Uncomment and customize as needed after testing each manager

  # Example ranger configuration (creates ~/.config/ranger/rc.conf)
  # xdg.configFile."ranger/rc.conf".text = ''
  #   # Enable image previews
  #   set preview_images true
  #   set preview_images_method kitty
  #
  #   # Vim-style line numbers
  #   set line_numbers relative
  #
  #   # Enable mouse support
  #   set mouse_enabled true
  # '';

  # Example lf configuration (creates ~/.config/lf/lfrc)
  # xdg.configFile."lf/lfrc".text = ''
  #   # Basic settings
  #   set previewer bat
  #   set cleaner true
  #
  #   # Custom key mappings (already vim-like by default)
  #   map D delete
  #   map x cut
  #   map v select
  # '';

  # Example vifm configuration would go in ~/.config/vifm/vifmrc
  # This file manager has the most comprehensive vim-like configuration options

  # Testing recommendations:
  # 1. Start with 'ranger' - most user-friendly with vim keybindings
  # 2. Try 'vifm' if you prefer dual-pane layout like mc
  # 3. Test 'lf' for lightweight, fast vim navigation
  # 4. Configure 'nnn' last as it requires more setup for vim-style use

  # Quick comparison:
  # ranger: Feature-rich, three-pane, excellent previews
  # vifm:   Most vim-like, dual-pane, comprehensive vim features
  # lf:     Lightweight, fast, clean vim keybindings
  # nnn:    Fast, configurable, needs setup for vim-style use
}
