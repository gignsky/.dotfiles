{
  pkgs,
  configLib,
  ...
}:

{
  # Additional packages for user-level bspwm functionality
  home.packages = with pkgs; [
    dmenu # Lightweight application launcher alternative
    xclip # Clipboard management (if not already installed system-wide)
    maim # Screenshots (if not already installed system-wide)
    xdotool # Window manipulation (if not already installed system-wide)
    nitrogen # Alternative wallpaper setter
  ];

  # Copy bspwm resource files to home directory
  home.file = {
    ".config/bspwm/resources/ganoslal.conf" = {
      source = configLib.relativeToRoot "home/gig/common/resources/bspwm/ganoslal.conf";
      executable = true;
    };
    ".config/bspwm/resources/merlin.conf" = {
      source = configLib.relativeToRoot "home/gig/common/resources/bspwm/merlin.conf";
      executable = true;
    };
    ".config/bspwm/resources/default.conf" = {
      source = configLib.relativeToRoot "home/gig/common/resources/bspwm/default.conf";
      executable = true;
    };
    #TODO SCOTTY! REMIND ME to figure out how to make these roatate through the tolkien folder
    # LOTR wallpaper
    ".background-image" = {
      source = configLib.relativeToRoot "home/gig/common/resources/wallpapers/tolkien/desktop/4k-doors-of-durin-horizontal.webp";
    };
    # # NixOS logo wallpaper
    # ".background-image" = {
    #   source = configLib.relativeToRoot "home/gig/common/resources/wallpapers/nixos-logo.png";
    # };
  };

  # Polybar status bar configuration
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
        font-0 = "DejaVu Sans:size=10;2";
        font-1 = "Font Awesome 6 Free:style=Solid:size=10;2";
        font-2 = "Font Awesome 6 Brands:size=10;2";

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

  # bspwm window manager configuration
  xsession.windowManager.bspwm = {
    enable = true;
    settings = {
      border_width = 5;
      window_gap = 15;
      split_ratio = 0.52;
      borderless_monocle = true;
      gapless_monocle = true;
      focus_follows_pointer = false;
      pointer_follows_focus = true;
      top_padding = 30; # Reserve space for polybar (30px height)
    };
    rules = {
      "Discord" = {
        desktop = "^9";
        follow = true;
      };
      "youtube-music" = {
        desktop = "^9";
        follow = true;
      };
      "ytmusicdesktop" = {
        desktop = "^9";
        follow = true;
      };
      # "Firefox" = {
      #   desktop = "^1";
      # };
      # "firefox" = {
      #   desktop = "^2";
      # };
    };
    extraConfig = ''
      # Load host-specific monitor configuration
      HOSTNAME=$(hostname)
      BSPWM_RESOURCES_DIR="$HOME/.config/bspwm/resources"

      echo "bspwm: Loading configuration for host: $HOSTNAME"

      if [ -f "$BSPWM_RESOURCES_DIR/$HOSTNAME.conf" ]; then
        echo "bspwm: Using host-specific config: $HOSTNAME.conf"
        source "$BSPWM_RESOURCES_DIR/$HOSTNAME.conf"
      elif [ -f "$BSPWM_RESOURCES_DIR/default.conf" ]; then
        echo "bspwm: Using default config: default.conf"
        source "$BSPWM_RESOURCES_DIR/default.conf"
      else
        echo "bspwm: No config files found, using fallback"
        # Fallback if no config files found
        bspc monitor -d I II III IV V VI VII VIII IX X
      fi

      # Start compositor for better visuals
      if command -v picom >/dev/null 2>&1; then
        picom --backend glx -b &
      fi
    '';
  };

  # sxhkd hotkey configuration
  services.sxhkd = {
    enable = true;
    keybindings = {
      # Terminal (using your preferred wezterm)
      "super + Return" = "wezterm";

      # Application launcher
      "super + space" = "rofi -show drun";
      "super + d" = "rofi -show drun"; # Alternative launcher binding

      # Help window - show bspwm keybindings
      "super + question" = ''
        rofi -dmenu -p "bspwm help" -i -markup-rows -no-custom -auto-select <<< "
        <b>Terminal & Applications:</b>
        super + Return                    Terminal (wezterm)
        super + space / super + d         Application launcher (rofi)
        super + ?                         Show this help window

        <b>Window Management:</b>
        super + w                         Close window
        super + shift + q                 Kill window
        super + shift + f                 Toggle fullscreen
        super + f                         Toggle floating
        super + t                         Toggle tiled
        super + m                         Minimize window
        super + shift + m                 Unhide/Restore last hidden window

        <b>Navigation:</b>
        super + h/j/k/l                   Focus window (west/south/north/east)
        super + shift + h/j/k/l           Swap window
        super + arrows                    Focus window (alternative)
        super + shift + arrows            Swap window (alternative)

        <b>Desktops:</b>
        super + 1-9/0/grave              Switch to desktop 1-11
        super + shift + 1-9/0/grave      Move window to desktop 1-11

        <b>Window Resizing:</b>
        super + alt + h/j/k/l            Resize window
        super + alt + shift + h/j/k/l    Resize window (alternative)

        <b>Screenshots:</b>
        Print                            Screenshot selection to clipboard
        super + Print                    Screenshot full screen to clipboard

        <b>System:</b>
        super + alt + Escape             Quit bspwm
        super + alt + r                  Restart bspwm

        <b>Audio:</b>
        XF86AudioRaiseVolume            Volume up
        XF86AudioLowerVolume            Volume down
        XF86AudioMute                   Mute toggle

        <b>Brightness:</b>
        XF86MonBrightnessUp             Brightness up (Function keys)
        XF86MonBrightnessDown           Brightness down (Function keys)
        super + plus / super + minus     Brightness up/down (alternative)
        super + shift + plus/minus       Large brightness adjustment
        "'';

      # Close window
      "super + w" = "bspc node -c";
      "super + shift + q" = "bspc node -k"; # Kill window

      # Quit bspwm
      "super + alt + Escape" = "bspc quit";

      # Restart bspwm
      "super + alt + r" = "bspc wm -r";

      # Focus/swap windows
      "super + {_,shift + }{h,j,k,l}" = "bspc node -{f,s} {west,south,north,east}";
      "super + {_,shift + }{Left,Down,Up,Right}" = "bspc node -{f,s} {west,south,north,east}";

      # Switch desktops (supports up to 11 desktops for multi-monitor)
      "super + {1-9,0,grave}" = "bspc desktop -f '^{1-9,10,11}'";

      # Move window to desktop (supports up to 11 desktops for multi-monitor)
      "super + shift + {1-9,0,grave}" = "bspc node -d '^{1-9,10,11}'";

      # Toggle fullscreen
      "super + shift + f" = "bspc node -t fullscreen";

      # Toggle floating
      "super + f" = "bspc node -t floating";

      # Toggle tiled
      "super + t" = "bspc node -t tiled";

      # Resize windows
      "super + alt + {h,j,k,l}" = "bspc node -z {left -20 0,bottom 0 20,top 0 -20,right 20 0}";
      "super + alt + shift + {h,j,k,l}" = "bspc node -z {right -20 0,top 0 20,bottom 0 -20,left 20 0}";

      # Minimize & Restore windows
      "super + m" = "bspc node -g hidden";
      "super + shift + m" =
        "bspc query -N -n .window.hidden | xargs -I {} bspc node {} --flag hidden=off";

      # Screenshots
      "Print" = "maim -s | xclip -selection clipboard -t image/png";
      "super + Print" = "maim | xclip -selection clipboard -t image/png";

      # Volume controls (if available)
      "XF86AudioRaiseVolume" = "pactl set-sink-volume @DEFAULT_SINK@ +5%";
      "XF86AudioLowerVolume" = "pactl set-sink-volume @DEFAULT_SINK@ -5%";
      "XF86AudioMute" = "pactl set-sink-mute @DEFAULT_SINK@ toggle";

      # Brightness controls (Framework 16 function keys)
      "XF86MonBrightnessUp" = "brightnessctl set +10%";
      "XF86MonBrightnessDown" = "brightnessctl set 10%-";

      # Alternative brightness bindings (in case function keys don't work)
      "super + plus" = "brightnessctl set +10%";
      "super + minus" = "brightnessctl set 10%-";
      "super + shift + plus" = "brightnessctl set +25%";
      "super + shift + minus" = "brightnessctl set 25%-";
    };
  };

  # X11 session configuration
  xsession = {
    enable = true;
    initExtra = ''
      # Set wallpaper (if exists)
      if [ -f "$HOME/.background-image" ]; then
        feh --bg-scale "$HOME/.background-image" &
      elif [ -f "$HOME/wallpaper.jpg" ]; then
        feh --bg-scale "$HOME/wallpaper.jpg" &
      elif [ -f "$HOME/wallpaper.png" ]; then
        feh --bg-scale "$HOME/wallpaper.png" &
      fi

      # Start sxhkd hotkey daemon
      sxhkd &

      # Polybar is managed by the services.polybar configuration above
      # No need to start it manually here
    '';
  };
}
