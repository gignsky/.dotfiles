{
  config,
  pkgs,
  configLib,
  ...
}:

# Wayland-native alternative to bspwm.nix. niri's own config is plain KDL
# text rather than a typed settings attrset, same reasoning as bspwm's
# extraConfig/sxhkd: it keeps every binary referenced by absolute store
# path and avoids depending on exactly how complete home-manager's niri
# module is.
{
  imports = [
    ./waybar.nix
    ./mako.nix
    ./swaylock.nix
  ];

  home.packages = with pkgs; [
    fuzzel # Application launcher (replaces rofi, which is X11-only)
    swaybg # Wallpaper setter (replaces feh, which is X11-only)
  ];

  # LOTR wallpaper (Gandalf and the Balrog). The only desktop art in the repo
  # is 1080x607, so this is a 4x Real-ESRGAN upscale of it; swap in the real
  # 4K version when available (see the tolkien/ notes file).
  home.file.".background-image" = {
    source = configLib.relativeToRoot "home/gig/common/resources/wallpapers/tolkien/desktop/upscaled/gandalf-and-balrog-upscaled-4x.webp";
  };

  xdg.configFile."niri/config.kdl".text = ''
    input {
        keyboard {
            xkb {
                layout "us"
            }
        }

        touchpad {
            tap
            natural-scroll
            dwt
            middle-emulation
        }
    }

    // Merlin is a single-display laptop; the docked-monitor case was already
    // unused (commented out) in the bspwm-era resource file, so it's not
    // ported. niri's auto scale picked 1.5 (1706x1066 logical) on this
    // 2560x1600 panel, which made text too big -- pin it lower. Try 1.0 for
    // even smaller, 1.25 -> 1.33 -> 1.5 for larger.
    output "eDP-1" {
        scale 1.25
    }

    // niri has no minimize. Emulate it by parking windows on this named
    // workspace; see the Mod+N binds.
    workspace "minimized"

    spawn-at-startup "${pkgs.swaybg}/bin/swaybg" "-i" "${config.home.homeDirectory}/.background-image" "-m" "fill"
    spawn-at-startup "${pkgs.waybar}/bin/waybar"
    spawn-at-startup "${pkgs.mako}/bin/mako"

    screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

    binds {
        Mod+Return { spawn "${pkgs.wezterm}/bin/wezterm"; }
        Mod+Space { spawn "${pkgs.fuzzel}/bin/fuzzel"; }

        Mod+W { close-window; }
        Mod+Shift+F { fullscreen-window; }
        Mod+F { toggle-window-floating; }

        // Maximize without fullscreen: bars/gaps stay. Mod+M fills the
        // column width of the screen, Mod+Shift+M expands to the edges.
        Mod+M { maximize-column; }
        Mod+Shift+M { maximize-window-to-edges; }

        // "Minimize": send the window to the minimized workspace without
        // following it. Mod+Shift+N jumps there, Mod+Ctrl+N returns to
        // the previous workspace; Mod+Shift+1..9 from that workspace restores a window to workspace N.
        Mod+N { move-window-to-workspace "minimized" focus=false; }
        Mod+Shift+N { focus-workspace "minimized"; }
        Mod+Ctrl+N { focus-workspace-previous; }

        // Keyboard resize (works on tiled and floating windows). Mouse
        // resize is built in: hold Mod and right-drag a window, or drag a
        // floating window's edge; Mod+left-drag moves it.
        Mod+Ctrl+H { set-window-width "-5%"; }
        Mod+Ctrl+L { set-window-width "+5%"; }
        Mod+Ctrl+K { set-window-height "-5%"; }
        Mod+Ctrl+J { set-window-height "+5%"; }
        Mod+Ctrl+Left { set-window-width "-5%"; }
        Mod+Ctrl+Right { set-window-width "+5%"; }
        Mod+Ctrl+Up { set-window-height "-5%"; }
        Mod+Ctrl+Down { set-window-height "+5%"; }

        // Two-finger touchpad scroll to move between windows. Held with Mod
        // because niri can't intercept an unmodified scroll without
        // stealing it from apps. Three-finger swipe does this natively.
        Mod+TouchpadScrollLeft cooldown-ms=150 { focus-column-left; }
        Mod+TouchpadScrollRight cooldown-ms=150 { focus-column-right; }

        // Focus/move. niri's column/row model, not bspwm's binary tree --
        // mapped semantically rather than forced 1:1.
        Mod+H { focus-column-left; }
        Mod+J { focus-window-down; }
        Mod+K { focus-window-up; }
        Mod+L { focus-column-right; }
        Mod+Shift+H { move-column-left; }
        Mod+Shift+J { move-window-down; }
        Mod+Shift+K { move-window-up; }
        Mod+Shift+L { move-column-right; }

        Mod+Left { focus-column-left; }
        Mod+Down { focus-window-down; }
        Mod+Up { focus-window-up; }
        Mod+Right { focus-column-right; }
        Mod+Shift+Left { move-column-left; }
        Mod+Shift+Down { move-window-down; }
        Mod+Shift+Up { move-window-up; }
        Mod+Shift+Right { move-column-right; }

        // Workspaces
        Mod+1 { focus-workspace 1; }
        Mod+2 { focus-workspace 2; }
        Mod+3 { focus-workspace 3; }
        Mod+4 { focus-workspace 4; }
        Mod+5 { focus-workspace 5; }
        Mod+6 { focus-workspace 6; }
        Mod+7 { focus-workspace 7; }
        Mod+8 { focus-workspace 8; }
        Mod+9 { focus-workspace 9; }
        Mod+0 { focus-workspace 10; }
        Mod+Shift+1 { move-column-to-workspace 1; }
        Mod+Shift+2 { move-column-to-workspace 2; }
        Mod+Shift+3 { move-column-to-workspace 3; }
        Mod+Shift+4 { move-column-to-workspace 4; }
        Mod+Shift+5 { move-column-to-workspace 5; }
        Mod+Shift+6 { move-column-to-workspace 6; }
        Mod+Shift+7 { move-column-to-workspace 7; }
        Mod+Shift+8 { move-column-to-workspace 8; }
        Mod+Shift+9 { move-column-to-workspace 9; }
        Mod+Shift+0 { move-column-to-workspace 10; }

        // Screenshots -- niri has this built in, no more maim/xclip/xdotool.
        Print { screenshot; }
        Mod+Print { screenshot-screen; }

        // Lock screen -- new, bspwm never had one.
        Mod+Shift+Escape { spawn "${pkgs.swaylock}/bin/swaylock"; }

        // Volume (same pactl calls bspwm's sxhkd config used)
        XF86AudioRaiseVolume { spawn "${pkgs.pulseaudio}/bin/pactl" "set-sink-volume" "@DEFAULT_SINK@" "+5%"; }
        XF86AudioLowerVolume { spawn "${pkgs.pulseaudio}/bin/pactl" "set-sink-volume" "@DEFAULT_SINK@" "-5%"; }
        XF86AudioMute { spawn "${pkgs.pulseaudio}/bin/pactl" "set-sink-mute" "@DEFAULT_SINK@" "toggle"; }

        // Brightness (same brightnessctl calls bspwm's sxhkd config used)
        XF86MonBrightnessUp { spawn "${pkgs.brightnessctl}/bin/brightnessctl" "set" "+10%"; }
        XF86MonBrightnessDown { spawn "${pkgs.brightnessctl}/bin/brightnessctl" "set" "10%-"; }
        Mod+Plus { spawn "${pkgs.brightnessctl}/bin/brightnessctl" "set" "+10%"; }
        Mod+Minus { spawn "${pkgs.brightnessctl}/bin/brightnessctl" "set" "10%-"; }

        Mod+Shift+Slash { show-hotkey-overlay; }
    }
  '';
}
