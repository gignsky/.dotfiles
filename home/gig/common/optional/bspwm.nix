{
  pkgs,
  configLib,
  ...
}:

let
  # Any keybinding whose command spans more than one line MUST go through
  # writeShellScript. `services.sxhkd.keybindings` emits the value under the
  # hotkey line but only indents the FIRST line, so line two lands in column 0 --
  # where sxhkd reads it as a new hotkey declaration, not a continuation. That
  # silently reduced `super + u` to its own leading comment (i.e. a no-op, which
  # is why minimized windows could never be brought back) and broke
  # `super + shift + w` outright. A store path is always one line.
  #
  # These also run with whatever PATH the sxhkd session happens to have, so
  # every binary is referenced by absolute store path.
  restoreLastHidden = pkgs.writeShellScript "bspwm-restore-last-hidden" ''
    # Most recently hidden window. -f focuses it, which also switches to
    # whichever desktop it lives on.
    ${pkgs.bspwm}/bin/bspc query -N -n .hidden.window \
      | ${pkgs.coreutils}/bin/tail -1 \
      | ${pkgs.findutils}/bin/xargs -I {} ${pkgs.bspwm}/bin/bspc node {} -g hidden=off -f
  '';

  # Same selector and same flag form as restoreLastHidden -- these two used to
  # disagree (`.window.hidden` / `--flag hidden=off`) for no reason.
  restoreAllHidden = pkgs.writeShellScript "bspwm-restore-all-hidden" ''
    ${pkgs.bspwm}/bin/bspc query -N -n .hidden.window \
      | ${pkgs.findutils}/bin/xargs -r -I {} ${pkgs.bspwm}/bin/bspc node {} -g hidden=off
  '';

  refreshWallpaper = pkgs.writeShellScript "bspwm-refresh-wallpaper" ''
    if [ -f "$HOME/.background-image" ]; then
      ${pkgs.feh}/bin/feh --bg-fill "$HOME/.background-image"
    fi
  '';
in

{
  imports = [
    ./polybar.nix
    # Compositor. Disabled by 066fb2e1 alongside polybar during the display
    # firefight; e5ae183c brought polybar back but not this. It matters for more
    # than transparency -- without a compositor every pointer-resize motion event
    # repaints the whole 5120x1440 surface untouched by damage tracking, which is
    # what made mouse resize feel like it only updated on release.
    ./picom.nix
  ];

  # Additional packages for user-level bspwm functionality
  home.packages = with pkgs; [
    dmenu # Lightweight application launcher alternative
    xclip # Clipboard management (if not already installed system-wide)
    maim # Screenshots (if not already installed system-wide)
    xdotool # Window manipulation (if not already installed system-wide)
    # nitrogen # Alternative wallpaper setter
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
    # Wallpaper. feh applies this per-monitor (it reads Xinerama info), so one
    # image covers every screen. The 5K source is 5120x2880 (16:9); --bg-fill
    # crops it to fit rather than squashing it onto the 32:9 ultrawide.
    # Alternatives in home/gig/common/resources/wallpapers/:
    #   SGA/Stargate_Atlantis_Gate_Fixed_Centered_5K Sharper.png  (same size, larger file)
    #   SGA/Stargate_Atlantis_Gate_Fixed_Centered_2560x1440.png   (lower res)
    #   nixos-logo.png
    # (the tolkien/desktop/ path referenced here previously does not exist —
    # only tolkien/mobile/ is in the repo)
    ".background-image" = {
      source = configLib.relativeToRoot "home/gig/common/resources/wallpapers/SGA/Stargate_Atlantis_Gate_Fixed_Centered_5K.png";
    };
  };

  # bspwm window manager configuration
  xsession.windowManager.bspwm = {
    enable = true;
    settings = {
      border_width = 5;
      window_gap = 13;
      split_ratio = 0.52;
      borderless_monocle = true;
      gapless_monocle = true;
      focus_follows_pointer = false;
      pointer_follows_focus = true;

      # Mouse move/resize. These four match bspwm's compiled-in defaults, but
      # nothing here used to set them, so the behaviour was implicit and would
      # move with any upstream default change.
      #
      # Worth knowing: bspwm has no live drag for TILED nodes -- super+left-drag
      # transplants the node only on button release, so it reads as doing
      # nothing. Live move/resize tracking is a floating-window feature; press
      # super + f first, then drag, and super + t to hand it back to the tiler.
      pointer_modifier = "mod4";
      pointer_action1 = "move";
      pointer_action2 = "resize_side";
      pointer_action3 = "resize_corner";
      # No manual padding for polybar: it sets _NET_WM_STRUT_PARTIAL and bspwm
      # honours struts, so reserving 30px here as well would double-count and
      # leave a gap under the bar. (If windows end up *behind* the bar instead,
      # put this back to 30 -- that means struts aren't being applied.)
      top_padding = 0;
    };
    rules = {
      "Discord" = {
        desktop = "IX";
        follow = true;
      };
      "youtube-music" = {
        desktop = "IX";
        follow = true;
      };
      "ytmusicdesktop" = {
        desktop = "IX";
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

      # Wallpaper. Set from bspwmrc rather than from the X session script so it
      # is re-applied by `bspc wm -r` (super + alt + r), which is also what
      # re-runs the monitor/desktop assignment above.
      if [ -f "$HOME/.background-image" ]; then
        ${pkgs.feh}/bin/feh --bg-fill "$HOME/.background-image" &
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
      "super + d" = "rofi -show run"; # Command launcher (nix run, scripts, executables)

      # Help window - show bspwm keybindings (fixed parsing)
      "super + question" = "${pkgs.writeShellScript "bspwm-help" ''
                ${pkgs.rofi}/bin/rofi -dmenu -p "bspwm help" -i -markup-rows -no-custom -auto-select <<EOF
        <b>Terminal & Applications:</b>
        super + Return                    Terminal (wezterm)
        super + space                     Desktop applications (rofi drun)
        super + d                         Command launcher (rofi run - nix run, scripts)
        super + ?                         Show this help window

        <b>Window Management:</b>
        super + w                         Close window
        super + shift + q                 Kill window
        super + shift + f                 Toggle fullscreen
        super + f                         Toggle floating
        super + t                         Toggle tiled
        super + m                         Minimize window
        super + u                         Restore last minimized window
        super + shift + m                 Pick a minimized window to restore
        super + shift + u                 Restore all minimized windows
        super + shift + w                 Refresh wallpaper/background

        <b>Navigation:</b>
        super + h/j/k/l                   Focus window (west/south/north/east)
        super + shift + h/j/k/l           Swap window
        super + arrows                    Focus window (alternative)
        super + shift + arrows            Swap window (alternative)

        <b>Desktops:</b>
        super + 1-9/0                    Switch to desktop I-X
        super + shift + 1-9/0            Move window to desktop I-X

        <b>Window Resizing:</b>
        super + alt + h/j/k/l            Resize window
        super + alt + shift + h/j/k/l    Resize window (alternative)

        <b>Mouse (super + drag):</b>
        super + left-drag                 Move window
        super + middle-drag               Resize nearest side
        super + right-drag                Resize nearest corner
        (tiled windows only swap on release -- super + f to float first)

        <b>Screenshots:</b>
        Print                            Screenshot selection to clipboard
        super + Print                    Screenshot full screen to clipboard

        <b>System:</b>
        super + alt + Escape             Quit bspwm
        super + alt + r                  Restart bspwm
        super + shift + d                Re-apply the monitor layout (ganoslal)

        <b>Audio:</b>
        XF86AudioRaiseVolume            Volume up
        XF86AudioLowerVolume            Volume down
        XF86AudioMute                   Mute toggle

        <b>Brightness:</b>
        XF86MonBrightnessUp             Brightness up (Function keys)
        XF86MonBrightnessDown           Brightness down (Function keys)
        super + plus / super + minus     Brightness up/down (alternative)
        super + shift + plus/minus       Large brightness adjustment
        EOF
      ''}";

      # Close window
      "super + w" = "bspc node -c";
      "super + shift + q" = "bspc node -k"; # Kill window

      # Quit bspwm
      "super + alt + Escape" = "bspc quit";

      # Restart bspwm
      "super + alt + r" = "bspc wm -r";

      # Re-apply the monitor layout by hand. Only ganoslal ships
      # `ganoslal-displays` (see hosts/ganoslal/nvidia.nix); the guard keeps
      # this a no-op on hosts that don't, since this module is shared.
      "super + shift + d" = "command -v ganoslal-displays >/dev/null && ganoslal-displays manual";

      # Focus/swap windows
      "super + {_,shift + }{h,j,k,l}" = "bspc node -{f,s} {west,south,north,east}";
      "super + {_,shift + }{Left,Down,Up,Right}" = "bspc node -{f,s} {west,south,north,east}";

      # Switch desktops. Selected BY NAME, not by '^N'.
      #
      # '^N' is bspwm's GLOBAL index, and global order follows RandR monitor
      # order rather than the order desktops are declared in the host .conf.
      # On ganoslal that made '^1' land on desktop V (top-left screen) while the
      # main screen's first desktop was '^7' — so the key, the label and the
      # screen all disagreed. Names are stable regardless of monitor ordering,
      # so super+N now always reaches desktop N and polybar's %name% label
      # matches the key that gets there.
      #
      # Ten desktops, so `grave` is deliberately unbound. XI used to be the
      # fifth desktop on the ultrawide, which meant that bar showed five labels
      # while super+5 jumped to the top-left screen — the last place where the
      # label and the key still disagreed. Both sxhkd sequences below must stay
      # balanced at ten elements.
      "super + {1-9,0}" = "bspc desktop -f {I,II,III,IV,V,VI,VII,VIII,IX,X}";

      # Move window to desktop (same by-name selection as above)
      "super + shift + {1-9,0}" = "bspc node -d {I,II,III,IV,V,VI,VII,VIII,IX,X}";

      # Toggle fullscreen
      "super + shift + f" = "bspc node -t fullscreen";

      # Toggle floating
      "super + f" = "bspc node -t floating";

      # Toggle tiled
      "super + t" = "bspc node -t tiled";

      # Resize windows
      "super + alt + {h,j,k,l}" = "bspc node -z {left -20 0,bottom 0 20,top 0 -20,right 20 0}";
      "super + alt + shift + {h,j,k,l}" = "bspc node -z {right -20 0,top 0 20,bottom 0 -20,left 20 0}";

      # Minimize & Restore windows. See the writeShellScript note at the top of
      # this file for why these are store paths and not inline commands.
      "super + m" = "bspc node -g hidden";
      "super + u" = "${restoreLastHidden}";
      "super + shift + u" = "${restoreAllHidden}";

      # Browse everything that is currently minimized and pick one to bring
      # back. Without this, hidden windows were only reachable newest-first
      # (super + u) or all at once (super + shift + u), with nothing showing
      # what was actually in there. The same script backs a left click on
      # polybar's `hidden` module.
      "super + shift + m" = "${pkgs.bspwm-hidden-picker}/bin/bspwm-hidden-picker";

      # Background/wallpaper refresh
      "super + shift + w" = "${refreshWallpaper}";

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
      # Monitor initialization is handled by displayManager.sessionCommands in nvidia.nix
      # This ensures all monitors are configured before display manager and BSPWM start

      # Set wallpaper (if exists)
      # if [ -f "$HOME/.background-image" ]; then
      #   feh --bg-scale "$HOME/.background-image" &
      # elif [ -f "$HOME/wallpaper.jpg" ]; then
      #   feh --bg-scale "$HOME/wallpaper.jpg" &
      # elif [ -f "$HOME/wallpaper.png" ]; then
      #   feh --bg-scale "$HOME/wallpaper.png" &
      # fi

      # Start sxhkd hotkey daemon
      sxhkd &
    '';
  };
}
