_:

{
  programs.firefox = {
    enable = true;

    # Force Cartograph as default font family
    # This ensures Firefox respects our font choices instead of falling back
    preferences = {
      # Set Cartograph as default sans-serif font
      "font.name.sans-serif.x-western" = "Cartograph CF";
      "font.name.serif.x-western" = "Artifex CF";
      "font.name.monospace.x-western" = "MonoLisa Variable";

      # Allow fontconfig to provide fallbacks for missing glyphs
      "gfx.font_rendering.fontconfig.max_generic_substitutions" = 127;

      # Ensure minimum font size doesn't interfere
      "font.minimum-size.x-western" = 0;
    };
  };
}
