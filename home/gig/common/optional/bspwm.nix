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
    # NixOS logo wallpaper
    ".background-image" = {
      source = configLib.relativeToRoot "home/gig/common/resources/wallpapers/nixos-logo.png";
    };
  };

  # bspwm window manager configuration
  xsession.windowManager.bspwm = {
    enable = true;
    settings = {
      border_width = 2;
      window_gap = 12;
      split_ratio = 0.52;
      borderless_monocle = true;
      gapless_monocle = true;
      focus_follows_pointer = true;
      pointer_follows_focus = false;
    };
    rules = {
      "Discord" = {
        desktop = "^8";
        follow = true;
      };
      "youtube-music" = {
        desktop = "^1";
        follow = true;
      };
      "ytmusicdesktop" = {
        desktop = "^1";
        follow = true;
      };
      "Firefox" = {
        desktop = "^2";
      };
      "firefox" = {
        desktop = "^2";
      };
      "code" = {
        desktop = "^3";
      };
      "Code" = {
        desktop = "^3";
      };
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
        picom -b &
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
      "super + f" = "bspc node -t fullscreen";

      # Toggle floating
      "super + s" = "bspc node -t floating";

      # Toggle tiled
      "super + t" = "bspc node -t tiled";

      # Resize windows
      "super + alt + {h,j,k,l}" = "bspc node -z {left -20 0,bottom 0 20,top 0 -20,right 20 0}";
      "super + alt + shift + {h,j,k,l}" = "bspc node -z {right -20 0,top 0 20,bottom 0 -20,left 20 0}";

      # Screenshots
      "Print" = "maim -s | xclip -selection clipboard -t image/png";
      "super + Print" = "maim | xclip -selection clipboard -t image/png";

      # Volume controls (if available)
      "XF86AudioRaiseVolume" = "pactl set-sink-volume @DEFAULT_SINK@ +5%";
      "XF86AudioLowerVolume" = "pactl set-sink-volume @DEFAULT_SINK@ -5%";
      "XF86AudioMute" = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
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

      # Optional: Start polybar if available
      # if command -v polybar >/dev/null 2>&1; then
      #   polybar &
      # fi
    '';
  };
}
