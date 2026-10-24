{
  # Notification daemon for niri. Entirely new -- bspwm never had one.
  services.mako = {
    enable = true;
    settings = {
      default-timeout = 5000;
      border-size = 2;
      border-color = "#88C0D0";
      background-color = "#2E3440";
      text-color = "#D8DEE9";
      max-visible = 5;

      "urgency=critical" = {
        border-color = "#BF616A";
        default-timeout = 0;
      };
    };
  };
}
