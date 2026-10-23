{
  # Screen locker for niri. Entirely new -- bspwm never had one. Bound to
  # Mod+Shift+Escape in niri.nix.
  programs.swaylock = {
    enable = true;
    settings = {
      color = "2E3440";
      font-size = 24;
      indicator-idle-visible = false;
      indicator-radius = 100;
      line-color = "88C0D0";
      ring-color = "4C566A";
      key-hl-color = "A3BE8C";
      wrong-color = "BF616A";
    };
  };
}
