{
  # Screen locker for niri (replaces swaylock, which only starts PAM -- and so
  # the fingerprint check -- after Enter is pressed, and stalled password
  # entry behind the fprintd timeout). hyprlock talks to fprintd over D-Bus in
  # parallel with the password prompt and speaks ext-session-lock, which niri
  # supports. Bound to Mod+Shift+Escape in niri.nix.
  programs.hyprlock = {
    enable = true;
    settings = {
      general.hide_cursor = true;
      auth = {
        "pam:enabled" = true;
        "fingerprint:enabled" = true;
      };
      background = [ { color = "rgb(46, 52, 64)"; } ];
      input-field = [
        {
          size = "300, 50";
          outline_thickness = 3;
          inner_color = "rgb(46, 52, 64)";
          outer_color = "rgb(136, 192, 208)";
          check_color = "rgb(163, 190, 140)";
          fail_color = "rgb(191, 97, 106)";
          font_color = "rgb(216, 222, 233)";
          fade_on_empty = false;
          placeholder_text = "Password or fingerprint";
          position = "0, 0";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
