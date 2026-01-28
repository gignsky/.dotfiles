{ pkgs, ... }:
{
  # Polybar status bar configuration

  ## bspwm specific
  xsession.windowManager.bspwm.extraConfig = ''
    # Start compositor for better visuals
    if command -v picom >/dev/null 2>&1; then
      picom --backend glx -b &
    fi
  '';

  ## the service
  services.polybar = {
    enable = true;
    package = pkgs.polybar.override {
      alsaSupport = true;
      githubSupport = true;
      mpdSupport = true;
      pulseSupport = true;
    };
    config = {
      "bar/main" = {
        # Bar positioning and appearance
        width = "100%";
        height = 30;
        radius = 0;
        fixed-center = true;
        bottom = false; # Explicitly set to top

        # Colors (Nord-inspired theme)
        background = "#2E3440";
        foreground = "#D8DEE9";
        line-size = 2;
        line-color = "#88C0D0";

        # Borders and padding
        border-size = 0;
        padding-left = 1;
        padding-right = 1;
        module-margin-left = 1;
        module-margin-right = 1;

        # Font configuration
        font-0 = "DejaVu Sans:size=11;2";
        font-1 = "Font Awesome 6 Free:style=Solid:size=11;2";
        font-2 = "Font Awesome 6 Brands:size=11;2";

        # Module layout
        modules-left = "bspwm";
        modules-center = "date";
        modules-right = "filesystem cpu memory pulseaudio wlan eth battery";

        # System tray
        tray-position = "right";
        tray-padding = 2;

        # Cursor actions
        cursor-click = "pointer";
        cursor-scroll = "ns-resize";

        # Enable IPC for bspwm integration
        enable-ipc = true;
      };

      # BSPWM workspace module
      "module/bspwm" = {
        type = "internal/bspwm";

        # Workspace labels
        label-focused = "%index%";
        label-focused-background = "#88C0D0";
        label-focused-foreground = "#2E3440";
        label-focused-padding = 2;

        label-occupied = "%index%";
        label-occupied-padding = 2;
        label-occupied-foreground = "#D8DEE9";

        label-urgent = "%index%!";
        label-urgent-background = "#BF616A";
        label-urgent-padding = 2;

        label-empty = "%index%";
        label-empty-foreground = "#4C566A";
        label-empty-padding = 2;
      };

      # Date and time module
      "module/date" = {
        type = "internal/date";
        interval = 5;

        # date = "%Y-%m-%d";
        date = "%m/%d";
        time = "%h:%M";

        format-prefix = "  ";
        format-prefix-foreground = "#88C0D0";

        label = "%date% %time%";
      };

      # CPU module
      "module/cpu" = {
        type = "internal/cpu";
        interval = 2;
        format-prefix = "CPU: ";
        format-prefix-foreground = "#88C0D0";
        label = "%percentage:2%%";
      };

      # Memory module
      "module/memory" = {
        type = "internal/memory";
        interval = 2;
        format-prefix = "MEM: ";
        format-prefix-foreground = "#88C0D0";
        label = "%percentage_used%%";
      };

      # Filesystem module
      "module/filesystem" = {
        type = "internal/fs";
        interval = 25;

        mount-0 = "/";

        label-mounted = " %percentage_used%%";
        label-unmounted = " %mountpoint% not mounted";
        label-unmounted-foreground = "#4C566A";
      };

      # PulseAudio module
      "module/pulseaudio" = {
        type = "internal/pulseaudio";

        format-volume = "<label-volume> <bar-volume>";
        label-volume = " %percentage%%";
        label-volume-foreground = "#D8DEE9";

        label-muted = " muted";
        label-muted-foreground = "#4C566A";

        bar-volume-width = 10;
        bar-volume-foreground-0 = "#A3BE8C";
        bar-volume-foreground-1 = "#A3BE8C";
        bar-volume-foreground-2 = "#A3BE8C";
        bar-volume-foreground-3 = "#A3BE8C";
        bar-volume-foreground-4 = "#A3BE8C";
        bar-volume-foreground-5 = "#EBCB8B";
        bar-volume-foreground-6 = "#D08770";
        bar-volume-gradient = false;
        bar-volume-indicator = "|";
        bar-volume-indicator-font = 2;
        bar-volume-fill = "─";
        bar-volume-fill-font = 2;
        bar-volume-empty = "─";
        bar-volume-empty-font = 2;
        bar-volume-empty-foreground = "#4C566A";
      };

      # Wireless network module
      "module/wlan" = {
        type = "internal/network";
        interface-type = "wireless";
        interval = 3;

        format-connected = "<ramp-signal> <label-connected>";
        label-connected = "%essid%";

        format-disconnected = "";

        ramp-signal-0 = "";
        ramp-signal-1 = "";
        ramp-signal-2 = "";
        ramp-signal-3 = "";
        ramp-signal-4 = "";
        ramp-signal-foreground = "#88C0D0";
      };

      # Ethernet module
      "module/eth" = {
        type = "internal/network";
        interface-type = "wired";
        interval = 3;

        format-connected-prefix = " ";
        format-connected-prefix-foreground = "#88C0D0";
        label-connected = "%local_ip%";

        format-disconnected = "";
      };

      # Battery module (for laptops)
      "module/battery" = {
        type = "internal/battery";
        battery = "BAT0";
        adapter = "ADP1";
        full-at = 98;

        format-charging = "<animation-charging> <label-charging>";
        format-discharging = "<animation-discharging> <label-discharging>";
        format-full-prefix = "BAT: ";
        format-full-prefix-foreground = "#A3BE8C";
        format-full = "<label-full>";

        ramp-capacity-0 = "";
        ramp-capacity-1 = "";
        ramp-capacity-2 = "";
        ramp-capacity-3 = "";
        ramp-capacity-4 = "";
        ramp-capacity-foreground = "#88C0D0";

        animation-charging-0 = "";
        animation-charging-1 = "";
        animation-charging-2 = "";
        animation-charging-3 = "";
        animation-charging-4 = "";
        animation-charging-foreground = "#A3BE8C";
        animation-charging-framerate = 750;

        animation-discharging-0 = "";
        animation-discharging-1 = "";
        animation-discharging-2 = "";
        animation-discharging-3 = "";
        animation-discharging-4 = "";
        animation-discharging-foreground = "#BF616A";
        animation-discharging-framerate = 750;
      };

      # Global WM settings
      "global/wm" = {
        margin-top = 0;
        margin-bottom = 0;
      };
    };
    script = "polybar main &";
  };
}
