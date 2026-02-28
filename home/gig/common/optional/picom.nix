_: {
  # Picom compositor configuration for window transparency and effects
  services.picom = {
    enable = true;
    backend = "glx";
    vSync = true;

    # Opacity settings - adjust these values to your preference
    # Values range from 0.0 (fully transparent) to 1.0 (fully opaque)
    settings = {
      # Active window opacity (focused window) - 83% opaque
      active-opacity = 0.90;

      # Inactive window opacity (unfocused windows) - 75% opaque
      inactive-opacity = 0.75;

      # Frame opacity (window borders/decorations) - 79% opaque
      frame-opacity = 0.50;

      # Opacity rules for specific window types or applications
      # opacity-rule = [
      #   "100:class_g = 'Firefox'" # Keep Firefox fully opaque
      #   "100:class_g = 'Chromium'" # Keep Chromium fully opaque
      #   "83:class_g = 'WezTerm'" # Terminal transparency matches active windows
      #   "75:class_g = 'Rofi'" # Application launcher matches inactive windows
      #   "83:class_g = 'Code'" # VS Code/editors matches active windows
      #   "100:class_g = 'mpv'" # Video player fully opaque
      #   "100:class_g = 'vlc'" # VLC fully opaque
      # ];

      # Fade settings
      fading = true;
      fade-in-step = 0.03;
      fade-out-step = 0.03;
      fade-delta = 5;

      # Shadow settings
      shadow = true;
      shadow-radius = 12;
      shadow-opacity = 0.75;
      shadow-offset-x = -12;
      shadow-offset-y = -12;

      # Exclude shadows for certain windows
      shadow-exclude = [
        "name = 'Notification'"
        "class_g = 'Conky'"
        "class_g ?= 'Notify-osd'"
        "class_g = 'Cairo-clock'"
        "_GTK_FRAME_EXTENTS@:c"
      ];

      # Performance and corner settings
      detect-rounded-corners = true;
      detect-client-opacity = true;
      detect-transient = true;
      use-damage = true;

      # Blur settings - subtle blur for active windows to improve readability
      blur-method = "dual_kawase";
      blur-strength = 2;
      blur-background = true;
      blur-background-frame = false;
      blur-background-fixed = false;

      # Only blur active windows for better readability
      blur-background-exclude = [
        "window_type = 'dock'"
        "window_type = 'desktop'"
        "_GTK_FRAME_EXTENTS@:c"
        "class_g = 'slop'" # Exclude screenshot selection
        "!focused" # Don't blur inactive windows
      ];
    };
  };
}
