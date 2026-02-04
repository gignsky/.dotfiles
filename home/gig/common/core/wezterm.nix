{
  programs.wezterm = {
    enable = true;
    extraConfig = ''
      local wezterm = require("wezterm")

      local config = wezterm.config_builder()

      config.font_size = 15.0
      config.font = wezterm.font_with_fallback({
        {
          family = "MonoLisa Mono",
          harfbuzz_features = {"calt=1", "liga=1", "dlig=1", "ss01=1", "ss02=1", "ss03=1", "ss04=1", "ss05=1"},
        },
        {
          family = "Cartograph CF",
          harfbuzz_features = {"calt=1", "liga=1", "dlig=1", "ss01=1", "ss02=1", "ss03=1", "ss04=1", "ss05=1", "ss06=1"},
        },
        {
          family = "GoMono Nerd Font Mono",
          harfbuzz_features = {"calt=1", "liga=1", "dlig=1", "ss01=1", "ss02=1"},
        },
      })

      -- Enable font ligatures and better rendering
      config.harfbuzz_features = {"calt=1", "liga=1", "dlig=1"}
      config.freetype_load_target = "Normal"
      config.freetype_render_target = "HorizontalLcd"

      config.hide_tab_bar_if_only_one_tab = true

      config.window_padding = {
      	left = 8,
      	right = 8,
      	top = 6,
      	bottom = 6,
      }

      config.window_decorations = "TITLE | RESIZE"

      -- config.keys = {
      --	{
      --		key = "Enter",
      --		mods = "ALT",
      --		action = wezterm.action.DisableDefaultAssignment,
      --	},
      -- }

      return config
    '';
  };
}
