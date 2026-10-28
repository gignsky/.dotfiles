{
  config,
  lib,
  pkgs,
  configLib,
  ...
}:

# Wayland-native alternative to bspwm.nix. niri's own config is plain KDL
# text rather than a typed settings attrset, same reasoning as bspwm's
# extraConfig/sxhkd: it keeps every binary referenced by absolute store
# path and avoids depending on exactly how complete home-manager's niri
# module is.
let
  # Mod+Return. Same launcher as bspwm.nix's super + Return, for the same
  # reason: on ganoslal a bare `wezterm` means `wezterm connect unix`, which
  # always starts a second GUI that re-opens every mux window. Ask the running
  # GUI for a window first; fall back to a fresh one only when none is up.
  #
  # Before that fresh GUI, make sure the mux server is already listening.
  # Left to itself `wezterm connect` spawns the server from inside its
  # "Connecting..." window and then swaps the first mux tab into that same
  # window. On niri the first GUI of the session came up frozen at exactly
  # that point, showing "Connect to Socket(...)" forever (2026-10-26; the
  # front-end side of it is in home/gig/common/core/wezterm.nix). Starting
  # the server here keeps the GUI out of the spawn path, and the GUI gets
  # its Wayland backend logged at debug level so a repeat leaves evidence in
  # $XDG_RUNTIME_DIR/wezterm/wezterm-gui-log-<pid>.txt.
  wezterm = config.programs.wezterm.package;
  #
  # The GUI check is a pgrep, not just the `wezterm cli` exit code: with no
  # GUI up but the mux server alive (every GUI crashed, which is how the
  # 2026-10-26 session ended), `wezterm cli spawn` happily talks to the mux
  # server instead, creates a window nobody can see and exits 0, so this key
  # would do nothing visible. Verified against a bare mux server.
  newTerminal = pkgs.writeShellScript "niri-new-terminal" ''
    if ${pkgs.procps}/bin/pgrep -u "$(${pkgs.coreutils}/bin/id -u)" -x wezterm-gui >/dev/null; then
      ${wezterm}/bin/wezterm cli --no-auto-start spawn --new-window >/dev/null 2>&1 && exit 0
    fi

    sock="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}/wezterm/sock"
    mux_up() {
      WEZTERM_UNIX_SOCKET="$sock" ${wezterm}/bin/wezterm cli --no-auto-start list >/dev/null 2>&1
    }
    if ! mux_up; then
      ${wezterm}/bin/wezterm-mux-server --daemonize
      for _ in $(${pkgs.coreutils}/bin/seq 1 50); do
        mux_up && break
        ${pkgs.coreutils}/bin/sleep 0.1
      done
    fi
    WEZTERM_LOG="window::os::wayland=debug,info" exec ${wezterm}/bin/wezterm
  '';

  # Mod+W. `close-window` is the wrong verb for a WezTerm window on
  # ganoslal: every window there belongs to the `unix` mux domain, and
  # WezTerm answers a compositor close on a mux-client window by detaching
  # from the domain, not by killing anything (mux/src/lib.rs
  # remove_window_internal -> Domain::detach; ClientPane reports a window
  # close as safe to do without a prompt). Detaching drops every window of
  # that domain at once, the GUI exits, and the next Mod+Return reconnects
  # and brings them all back untouched. Observed on niri 2026-10-26; the GUI
  # log ends in "detaching domain" / "domain detached panes: [...]".
  #
  # So for WezTerm, kill the panes of the focused window on the mux server
  # instead. The server records each client's focused pane (ClientPane
  # forwards it with SetFocusedPane), so `list-clients` names the pane under
  # the cursor, `list` gives the window it belongs to, and `kill-pane` on
  # each pane of that window makes the GUI drop just that window. Pane and
  # window ids differ between the GUI socket and the server socket, so
  # everything here talks to the server explicitly. Anything else, and any
  # lookup failure, falls back to a plain close-window.
  closeWindow = pkgs.writeShellScript "niri-close-window" ''
    niri=${pkgs.niri}/bin/niri
    jq=${pkgs.jq}/bin/jq
    wezterm=${wezterm}/bin/wezterm
    fallback() { exec "$niri" msg action close-window; }

    app_id=$("$niri" msg --json focused-window | "$jq" -r '.app_id // empty') || fallback
    [ "$app_id" = "org.wezfurlong.wezterm" ] || fallback

    export WEZTERM_UNIX_SOCKET="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}/wezterm/sock"
    cli() { "$wezterm" cli --no-auto-start "$@"; }

    # Several clients (a second GUI, `wezterm cli` itself) may be attached;
    # the one that acted most recently is the GUI the user is looking at.
    pane=$(cli list-clients --format json | "$jq" -r '
      map(select(.focused_pane_id != null))
      | sort_by(.idle_time.secs, .idle_time.nanos)
      | .[0].focused_pane_id // empty') || fallback
    [ -n "$pane" ] || fallback

    panes=$(cli list --format json | "$jq" -r --argjson p "$pane" '
      (map(select(.pane_id == $p)) | .[0].window_id) as $w
      | if $w == null then empty else map(select(.window_id == $w) | .pane_id) | .[] end') || fallback
    [ -n "$panes" ] || fallback

    for p in $panes; do
      cli kill-pane --pane-id "$p"
    done
  '';

  # Mod+Alt+R. niri port of `ganoslal-displays refresh` (bspwm's super + alt
  # + r), the cure for a panel that stays dark after sleep while the
  # compositor believes it is lit -- ganoslal's DP-5 ultrawide, observed
  # 2026-10-15. Re-applying the same mode is a no-op to the driver and never
  # retrains the DP link, so every output is turned off and back on to force
  # a real modeset. Host-agnostic: it cycles whatever outputs are connected.
  #
  # All outputs go off together and come back together, same as the X
  # version. niri re-applies each output's mode/position from config.kdl
  # when it comes back, and workspaces return to the monitor they came from.
  # Logs to the journal: journalctl --user -t niri-refresh-displays
  refreshDisplays = pkgs.writeShellScript "niri-refresh-displays" ''
    set -u
    niri=${pkgs.niri}/bin/niri
    log() { ${pkgs.util-linux}/bin/logger -t niri-refresh-displays "$*"; }

    # A panel that is merely DPMS-blanked wakes on this alone.
    $niri msg action power-on-monitors || log "power-on-monitors failed"

    outputs=$($niri msg --json outputs | ${pkgs.jq}/bin/jq -r 'keys | join(" ")') || {
      log "could not list outputs"
      exit 1
    }
    if [ -z "$outputs" ]; then
      log "no connected outputs, nothing to cycle"
      exit 1
    fi

    # Unquoted on purpose: connector names never contain whitespace.
    for o in $outputs; do
      $niri msg output "$o" off || log "could not turn $o off"
    done
    log "outputs off: $outputs"
    # Long enough for the panels to notice the link drop; some monitors
    # treat an instant off/on as no change and stay asleep.
    sleep 1
    for o in $outputs; do
      $niri msg output "$o" on || log "could not turn $o back on"
    done
    log "outputs on: $outputs"
  '';
  # Mod+V clipboard history. The db lives in XDG_RUNTIME_DIR (tmpfs), so
  # history starts empty after a reboot and never lands on disk.
  cliphistDb = "\${XDG_RUNTIME_DIR:-/tmp}/cliphist.db";
  clipboardWatch = pkgs.writeShellScript "niri-clipboard-watch" ''
    export PATH=${
      lib.makeBinPath [
        pkgs.wl-clipboard
        pkgs.cliphist
      ]
    }:$PATH
    wl-paste --type text --watch cliphist -db-path "${cliphistDb}" store &
    wl-paste --type image --watch cliphist -db-path "${cliphistDb}" store &
    wait
  '';
  clipboardHistory = pkgs.writeShellScript "niri-clipboard-history" ''
    export PATH=${
      lib.makeBinPath [
        pkgs.wl-clipboard
        pkgs.cliphist
        pkgs.fuzzel
      ]
    }:$PATH
    cliphist -db-path "${cliphistDb}" list \
      | fuzzel --dmenu --prompt "clipboard> " \
      | cliphist -db-path "${cliphistDb}" decode \
      | wl-copy
  '';
in
{
  options.niriHostConfig = lib.mkOption {
    type = lib.types.lines;
    default = "";
    description = ''
      Host-specific niri KDL (outputs, render device, ...), spliced into
      config.kdl. Set from the host's home entry point (merlin.nix,
      ganoslal.nix) so this module stays host-agnostic.
    '';
  };

  imports = [
    ./waybar.nix
    ./mako.nix
    ./swaylock.nix
  ];

  config = {
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

      ${config.niriHostConfig}

      // niri has no minimize. Emulate it by parking windows on this named
      // workspace; see the Mod+N binds.
      workspace "minimized"

      // WezTerm on Wayland waits for a configure event with a zero size
      // before it will draw, so a window niri gives a concrete width (the
      // default 50% column) can stay blank or never map. It hit ganoslal's
      // 5120-wide DP-5 but not the 1920-wide DP-1. An empty
      // default-column-width lets WezTerm pick its own size. Workaround from
      // niri's Application-Issues wiki.
      window-rule {
          match app-id=r#"^org\.wezfurlong\.wezterm$"#
          default-column-width {}
      }

      spawn-at-startup "${pkgs.swaybg}/bin/swaybg" "-i" "${config.home.homeDirectory}/.background-image" "-m" "fill"
      spawn-at-startup "${pkgs.waybar}/bin/waybar"
      spawn-at-startup "${pkgs.mako}/bin/mako"
      spawn-at-startup "${clipboardWatch}"
      // A Wayland clipboard dies with the app that owns it; this keeps a copy
      // alive after the source window closes.
      spawn-at-startup "${pkgs.wl-clip-persist}/bin/wl-clip-persist" "--clipboard" "regular"

      screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

      binds {
          Mod+Return { spawn "${newTerminal}"; }
          Mod+Space { spawn "${pkgs.fuzzel}/bin/fuzzel"; }
          Mod+V { spawn "${clipboardHistory}"; }

          Mod+W { spawn "${closeWindow}"; }
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
          Mod+Alt+J { focus-workspace-down; }
          Mod+Alt+K { focus-workspace-up; }
          Mod+Shift+H { move-column-left; }
          Mod+Shift+J { move-window-down; }
          Mod+Shift+K { move-window-up; }
          Mod+Shift+L { move-column-right; }

          // Monitors (multi-head hosts; a no-op on a single display). Alt is
          // already the "beyond this workspace" modifier via Mod+Alt+J/K, so
          // arrows/H/L pick the neighbouring monitor in that direction.
          Mod+Alt+H { focus-monitor-left; }
          Mod+Alt+L { focus-monitor-right; }
          Mod+Alt+Left { focus-monitor-left; }
          Mod+Alt+Right { focus-monitor-right; }
          Mod+Alt+Up { focus-monitor-up; }
          Mod+Alt+Down { focus-monitor-down; }
          Mod+Alt+Shift+H { move-column-to-monitor-left; }
          Mod+Alt+Shift+L { move-column-to-monitor-right; }
          Mod+Alt+Shift+Left { move-column-to-monitor-left; }
          Mod+Alt+Shift+Right { move-column-to-monitor-right; }
          Mod+Alt+Shift+Up { move-column-to-monitor-up; }
          Mod+Alt+Shift+Down { move-column-to-monitor-down; }

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
          Mod+Shift+1 { move-column-to-workspace 1 focus=false; }
          Mod+Shift+2 { move-column-to-workspace 2 focus=false; }
          Mod+Shift+3 { move-column-to-workspace 3 focus=false; }
          Mod+Shift+4 { move-column-to-workspace 4 focus=false; }
          Mod+Shift+5 { move-column-to-workspace 5 focus=false; }
          Mod+Shift+6 { move-column-to-workspace 6 focus=false; }
          Mod+Shift+7 { move-column-to-workspace 7 focus=false; }
          Mod+Shift+8 { move-column-to-workspace 8 focus=false; }
          Mod+Shift+9 { move-column-to-workspace 9 focus=false; }
          Mod+Shift+0 { move-column-to-workspace 10 focus=false; }

          // Screenshots -- niri has this built in, no more maim/xclip/xdotool.
          Print { screenshot; }
          Mod+Print { screenshot-screen; }

          // Lock screen -- new, bspwm never had one.
          Mod+Shift+Escape { spawn "${pkgs.swaylock}/bin/swaylock"; }

          // Full display refresh: power-cycle every output (see
          // refreshDisplays above). For a monitor that stays dark after sleep.
          Mod+Alt+R { spawn "${refreshDisplays}"; }

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
  };
}
