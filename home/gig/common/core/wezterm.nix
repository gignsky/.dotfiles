{
  programs.wezterm = {
    enable = true;
    extraConfig = ''
      local wezterm = require("wezterm")

      local config = wezterm.config_builder()

      config.font_size = 15.0

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
