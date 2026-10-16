{
  config,
  lib,
  pkgs,
  configVars,
  ...
}:
let
  # Applies the 4-monitor layout. Invoked from FOUR places, all the same store
  # path, dispatched on the context argument:
  #
  #   login   sessionCommands below, before bspwm starts
  #   resume  the post-sleep unit below
  #   manual  sxhkd `super + shift + d` (home/gig/common/optional/bspwm.nix)
  #   verify  the user timer below -- side-effect-free unless the layout drifted
  #
  # `login` is the authoritative apply and is free to block: the LightDM session
  # wrapper runs it at line 53, before `nixos-fake-graphical-session.target`
  # (66) and before `exec ~/.xsession` (72) starts bspwm. That ordering is what
  # bspwmrc's `bspc monitor DP-1-1 -d VII VIII` depends on, so this must not be
  # moved to a graphical-session.target unit.
  applyDisplays = pkgs.writeShellScriptBin "ganoslal-displays" ''
    set -u
    # No `set -e` on purpose: several steps are expected to fail benignly, and a
    # failed xrandr must still reach the logging at the bottom -- which is the
    # only diagnostic available when the screens are wrong. Calls that matter
    # are checked explicitly instead.
    #
    # PATH is pinned with NO trailing :$PATH. The point of pinning is that all
    # four contexts (xsession, two systemd units, sxhkd) behave identically;
    # appending the inherited PATH defeats that. Note `sed` and `awk` are NOT
    # here -- add pkgs.gnused to this list in the same commit if you ever need
    # them, rather than relying on an inherited one.
    export PATH=${
      lib.makeBinPath [
        pkgs.coreutils
        pkgs.gnugrep
        pkgs.systemd
      ]
    }

    XRANDR=${pkgs.xrandr}/bin/xrandr
    BSPC=${pkgs.bspwm}/bin/bspc
    LOG=/tmp/xrandr-init.log
    CTX="''${1:-manual}"

    # The resume unit is a system unit running as this user, so it has no
    # XDG_RUNTIME_DIR of its own; the other three contexts do.
    : "''${XDG_RUNTIME_DIR:=/run/user/${toString configVars.uid}}"
    export XDG_RUNTIME_DIR
    PAUSE="$XDG_RUNTIME_DIR/ganoslal-displays.pause"

    # /tmp is NOT cleaned on boot on this host (boot.tmp.cleanOnBoot is unset),
    # which is what made the login history readable far enough back to find the
    # race. Keep the file -- it is the "diagnose over SSH with no working
    # screen" affordance -- but cap it so it does not grow for the life of the
    # install.
    if [ -f "$LOG" ] && [ "$(wc -c < "$LOG")" -gt 262144 ]; then
      : > "$LOG"
    fi

    # Both sinks: journald captures stdout in all four contexts (the session
    # wrapper re-execs itself under `systemd-cat -t xsession`), and the file
    # survives a session that never came up.
    log() { printf 'ganoslal-displays[%s]: %s\n' "$CTX" "$*" | tee -a "$LOG"; }

    # Physical layout:
    #   [HDMI-0] [DP-1-1] [DP-1]   top row, 1920x1080@60 each (5760 wide)
    #            [DP-2]            bottom center, 5120x1440@144, primary
    # DP-2 is centred under the top row: (5760 - 5120) / 2 = 320.
    #
    # name:mode:rate:XxY -- the first present entry gets --primary, i.e. DP-2
    # whenever it is connected. DP-2 must NEVER get --auto: its EDID-preferred
    # mode is 1920x1080, so --auto hands the ultrawide a 1080p mode. That is
    # exactly the `DP-2 1920/1200x1080/330+0+0` line the 2026-10-15 13:29
    # fallback left in the log.
    EXPECTED="DP-2:5120x1440:144:320x1080 HDMI-0:1920x1080:60:0x0 DP-1-1:1920x1080:60:1920x0 DP-1:1920x1080:60:3840x0"

    # "5120x1440+320+1080" from mode 5120x1440 and pos 320x1080.
    expected_geom() { printf '%s+%s+%s' "$1" "''${2%x*}" "''${2#*x}"; }

    # ONE cached snapshot per decision, rather than one `xrandr --query` per
    # output. The old all_present() spread its verdict over four round-trips to
    # X with 2>/dev/null swallowing failures, so any single transient query
    # failure in that window read as "a monitor is missing" and dropped us into
    # the destructive fallback with no record of which output or why.
    QUERY=""
    refresh_query() {
      if ! QUERY=$($XRANDR --query 2>&1); then
        log "xrandr --query failed: $QUERY"
        QUERY=""
        return 1
      fi
      # A query with no screen line is not evidence that a monitor is missing --
      # it means we could not talk to X yet. Treat it as "retry", never as
      # "reconfigure".
      case "$QUERY" in
        *"Screen 0"*) return 0 ;;
      esac
      log "xrandr --query returned no screen line"
      QUERY=""
      return 1
    }

    # `^$1 connected` is unambiguous: DP-1 does not match "DP-1-1 connected",
    # and " connected" does not match "disconnected" (the space precedes the d).
    connected() { printf '%s\n' "$QUERY" | grep -q "^$1 connected"; }

    # Current geometry of an output, e.g. "5120x1440+320+1080". Empty when the
    # output is connected but not lit.
    geom() {
      printf '%s\n' "$QUERY" | grep "^$1 connected" \
        | grep -oE '[0-9]+x[0-9]+\+[0-9]+\+[0-9]+' | head -n1
    }

    missing_outputs() {
      m=""
      for entry in $EXPECTED; do
        name=''${entry%%:*}
        connected "$name" || m="$m $name"
      done
      printf '%s' "''${m# }"
    }

    # Attach the secondary GPU (GTX 970) to the primary GPU's X screen so its
    # outputs are usable. Provider-name based, not output-name based, so it is
    # unaffected by output renaming. This used to be a bare `|| true`, which
    # left no trace when it failed -- and it CAN fail, because the provider may
    # not be registered yet this early in the session. DP-1-1 cannot appear
    # until this succeeds.
    link_provider() {
      if ! $XRANDR --listproviders 2>/dev/null | grep -q 'name:NVIDIA-G0'; then
        log "provider NVIDIA-G0 not registered yet"
        return 1
      fi
      if out=$($XRANDR --setprovideroutputsource NVIDIA-G0 NVIDIA-0 2>&1); then
        return 0
      fi
      log "provider attach failed: $out"
      return 1
    }

    # Build ONE atomic xrandr call from EXPECTED, naming only outputs that are
    # actually present.
    #
    # A single xrandr call that mentions an absent output fails as a WHOLE and
    # silently leaves the old layout in place -- that is how this host ended up
    # mirrored before. But the old code's answer to a missing output was to
    # re-lay EVERYTHING out left-to-right with --auto, which flattened the two
    # rows into one and dropped the ultrawide to 1080p. A partial apply costs
    # only a gap in the X screen where the absent monitor belongs, and leaves
    # the monitors that ARE there exactly where they were.
    apply_layout() {
      args=""
      present=0
      for entry in $EXPECTED; do
        rest=''${entry#*:}
        name=''${entry%%:*}
        mode=''${rest%%:*}
        rest=''${rest#*:}
        rate=''${rest%%:*}
        pos=''${rest#*:}
        connected "$name" || continue
        present=$((present + 1))
        # Expanded unquoted just below on purpose: these are xrandr flags, none
        # of which can contain whitespace.
        args="$args --output $name --mode $mode --rate $rate --pos $pos"
        [ "$present" -eq 1 ] && args="$args --primary"
      done

      if [ "$present" -eq 0 ]; then
        log "no expected output is connected, leaving the layout alone"
        return 1
      fi

      if $XRANDR $args; then
        log "applied layout ($present/4 expected outputs)"
      else
        rc=$?
        log "xrandr FAILED rc=$rc for:$args"
        return "$rc"
      fi

      # Anything connected that is not in EXPECTED (a TV plugged into the 970,
      # say) is placed by a SEPARATE best-effort call, so it cannot take the
      # atomic call above down with it.
      for out in $(printf '%s\n' "$QUERY" | grep " connected" | cut -d' ' -f1); do
        case " $EXPECTED " in
          *" $out:"*) continue ;;
        esac
        log "unexpected connected output $out, placing right of DP-1"
        $XRANDR --output "$out" --auto --right-of DP-1 || log "could not place $out"
      done
    }

    # Wait for the full output set in EVERY context -- not just resume, which is
    # the bug this whole rewrite is about. DP-1-1 lives on the GTX 970 and
    # cannot appear until link_provider succeeds and its DP link trains; at
    # login that can land hundreds of ms after the first query. The old code
    # only waited on resume, so a late DP-1-1 at login tripped the guard and the
    # --auto fallback scattered all four monitors (observed 2026-10-15 13:29).
    #
    # Early exit means a healthy boot pays nothing. The 15s ceiling is only ever
    # paid when a monitor is genuinely absent, and a one-time 15s slower session
    # start beats a scrambled desktop. LightDM does not watchdog
    # sessionCommands, so blocking here is safe.
    do_apply() {
      link_provider || true
      attempt=0
      while :; do
        if refresh_query && [ -z "$(missing_outputs)" ]; then
          break
        fi
        attempt=$((attempt + 1))
        [ "$attempt" -ge 30 ] && break
        # The provider itself may have been unregistered on the first try.
        [ $((attempt % 6)) -eq 0 ] && link_provider
        sleep 0.5
      done

      # Always record the wait, so every boot leaves evidence of how close this
      # host came to losing the race again.
      if [ "$attempt" -gt 0 ]; then
        log "waited $((attempt / 2)).$(((attempt % 2) * 5))s for outputs"
      fi

      still_missing=$(missing_outputs)
      if [ -n "$still_missing" ]; then
        log "missing after wait:$(printf '%s' " $still_missing")"
      fi

      apply_layout
    }

    layout_matches() {
      for entry in $EXPECTED; do
        rest=''${entry#*:}
        name=''${entry%%:*}
        mode=''${rest%%:*}
        pos=''${rest#*:}
        pos=''${pos#*:}
        [ "$(geom "$name")" = "$(expected_geom "$mode" "$pos")" ] || return 1
      done
      # Geometry alone would miss a silent 144 -> 60 drop on DP-2, which is a
      # real post-resume nvidia failure. DP-2 is the only output on this host
      # that offers 5120x1440, so no per-output block parsing is needed (and no
      # sed, which is not on the pinned PATH).
      printf '%s\n' "$QUERY" | grep -qE '^ +5120x1440 +14[34]\.[0-9]+\*'
    }

    # Side-effect-free unless the layout actually drifted. This is what makes it
    # safe to run on a two-minute timer: no RandR call is issued, and nothing is
    # logged, when the layout is already right.
    do_verify() {
      [ -e "$PAUSE" ] && return 0
      # A failed query or a genuinely absent monitor is not drift: do nothing
      # and stay quiet, so the log only ever records real corrections.
      refresh_query || return 0
      [ -z "$(missing_outputs)" ] || return 0
      layout_matches && return 0

      log "layout drifted (DP-2=$(geom DP-2) HDMI-0=$(geom HDMI-0) DP-1-1=$(geom DP-1-1) DP-1=$(geom DP-1)), re-applying"
      apply_layout || return $?
      refresh_query || true

      # A re-apply after bspwm is already up leaves two things stale.
      #
      # 1. bspwm creates a re-enabled monitor with a default desktop, so the
      #    names from ganoslal.conf are gone -- user-visible as "my workspaces
      #    are on the wrong screen". `bspc wm -r` re-runs bspwmrc, which
      #    re-sources ganoslal.conf (and re-applies the wallpaper). Windows
      #    survive; sxhkd is a separate scope and is unaffected. Gated on bspwm
      #    having ACTUALLY lost a monitor, not on any geometry change, so a
      #    plain mode correction never restarts the WM.
      names=$($BSPC query -M --names 2>/dev/null || true)
      for entry in $EXPECTED; do
        name=''${entry%%:*}
        connected "$name" || continue
        if ! printf '%s\n' "$names" | grep -q "^$name$"; then
          log "bspwm is missing monitor $name, restarting bspwm to re-run ganoslal.conf"
          $BSPC wm -r || log "bspc wm -r failed"
          break
        fi
      done

      # 2. polybar spawns one bar per monitor at session start and picks the
      #    tray position from whichever output is primary, so bars are left
      #    positioned for the old geometry. Restarting the user service
      #    re-runs that launch loop.
      systemctl --user restart polybar.service 2>/dev/null \
        || log "could not restart polybar (not running?)"
    }

    case "$CTX" in
      verify)
        do_verify
        ;;
      *) # login | resume | manual
        do_apply
        log "complete ($(date))"
        $XRANDR --listmonitors | tee -a "$LOG"
        ;;
    esac
  '';
in
# Dual-NVIDIA GPU configuration for ganoslal's 4-monitor setup.
# There is no AMD GPU in this machine — both cards are NVIDIA:
#
#   RTX 3060 Ti  PCI 2d:00.0  (decimal 45)  <- pinned as the X primary below
#   GTX 970      PCI 23:00.0  (decimal 35)
#
# IMPORTANT: NVIDIA derives RandR output names from provider order, so the
# names below are only stable as long as the primary GPU is pinned. X defaults
# to the lowest PCI bus, which would pick the GTX 970 (0x23 < 0x2d) and rename
# every output — that is exactly what broke this host previously. The BusID in
# deviceSection is what keeps the naming below true.
#
#   RTX 3060 Ti (NVIDIA-0, Source Output)
#     DP-2      5120x1440@144  ultrawide, bottom center
#     HDMI-0    1920x1080@60   top left
#     DP-1      1920x1080@60   top right
#   GTX 970 (NVIDIA-G0, Sink Output — driven via PRIME output offload)
#     DP-1-1    1920x1080@60   top center (LG IPS235)
#
# The monitor layout is applied in displayManager.sessionCommands below.
# DP-1-1 in particular reports connected with a valid mode list but is never
# given a CRTC automatically, so it stays dark unless explicitly enabled.
#
# Ref: https://nixos.wiki/wiki/Nvidia
{
  nixpkgs.config.allowUnfree = lib.mkForce true;
  nixpkgs.config.nvidia.acceptLicense = true;
  boot.kernelParams = [ "nvidia-drm.fbdev=1" ];

  hardware = {
    nvidia = {
      # MUST stay on the 580 branch: NVIDIA dropped Maxwell (GTX 900 series),
      # Pascal and Volta support in 590, and this box has a GTX 970. On 26.05
      # `nvidiaPackages.stable` is 595.71.05, which would leave the 970
      # unsupported and take DP-1-1 (top center) offline with it. legacy_580
      # is 580.173.02 — the final branch that still supports Maxwell, and it
      # drives the RTX 3060 Ti perfectly well too.
      package = config.boot.kernelPackages.nvidiaPackages.legacy_580;

      # Enable kernel modesetting (required for 535+, prevents screen tearing)
      modesetting.enable = true;

      # Use proprietary kernel modules (GTX 970 doesn't support open modules)
      # RTX 3060 Ti could use open=true with driver 560+, but GTX 970 requires proprietary
      open = false;

      # Enable NVIDIA Control Panel
      nvidiaSettings = true;

      # NOTE: PRIME is for hybrid laptop configurations (integrated + discrete GPU).
      # For two discrete NVIDIA GPUs we don't use hardware.nvidia.prime at all —
      # the second card is attached at runtime as a RandR output sink instead
      # (see displayManager.sessionCommands below).

      # Enable power management for better stability
      powerManagement = {
        enable = lib.mkDefault true;
      };
    };

    # Graphics subsystem configuration
    graphics = {
      enable = true;
      enable32Bit = true; # Support for 32-bit applications/games
    };
  };

  # Configure X11 to recognize both NVIDIA GPUs
  services.xserver = {
    # Expose outputs from BOTH GPUs on a single unified screen. Without this,
    # X11 only ever sees the primary GPU's outputs.
    serverFlagsSection = ''
      Option "AllowMouseOpenFail" "True"
      Option "AutoAddGPU" "True"
    '';

    # Let the nvidia driver bring up the screen even with no monitor attached
    # to the primary output at server start.
    screenSection = ''
      Option "AllowEmptyInitialConfiguration" "True"
    '';

    # Spliced into the generated Section "Device" / Identifier "Device-nvidia[0]".
    deviceSection = ''
      # Pin the RTX 3060 Ti (PCI 2d:00.0) as X's primary device. X wants this in
      # DECIMAL, so 0x2d -> 45. Without it X picks the lowest bus (the GTX 970)
      # and every RandR output gets renamed.
      BusID "PCI:45:0:0"
      # Probe and enable all connected outputs across all GPUs
      Option "ProbeAllGpus" "True"
      Option "AllowExternalGpus" "True"
    '';

    # Runs per-session, after login, before the window manager starts — so the
    # monitors exist by the time bspwmrc assigns desktops to them.
    displayManager.sessionCommands = "${applyDisplays}/bin/ganoslal-displays login";
  };

  # `ganoslal-displays` on PATH, so the layout can also be re-applied by hand
  # (super + shift + d, see home/gig/common/optional/bspwm.nix).
  environment.systemPackages = [ applyDisplays ];

  # All the systemd units this host needs for its displays live in one attrset
  # so `systemd` is assigned exactly once (statix: "Avoid repeated keys").
  systemd = {

    # Re-apply the layout on wake.
    #
    # sessionCommands only runs once, at login. After a suspend/resume cycle the
    # driver can drop a mode and nothing puts it back — observed 2026-09-16, when
    # the other monitors woke but the DP-2 ultrawide stayed dark until the next
    # login. A unit that is both `after` and `wantedBy` sleep.target runs on the
    # way back up, not on the way down.
    services.ganoslal-displays-resume = {
      description = "Re-apply ganoslal monitor layout after resume";
      after = [ "sleep.target" ];
      wantedBy = [ "sleep.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = configVars.username;
        # X is already running and owned by the user session; the layout script
        # needs to talk to it. Verified against the live session on this host.
        Environment = [
          "DISPLAY=:0"
          "XAUTHORITY=/home/${configVars.username}/.Xauthority"
        ];
        ExecStart = "${applyDisplays}/bin/ganoslal-displays resume";
      };
    };

    # Periodic, side-effect-free verification of the layout.
    #
    # sessionCommands fires once, at login, and the resume unit only covers
    # suspend. Nothing hooked a later RandR change: a panel power cycle, a DPMS
    # glitch, a KVM switch or a late GPU probe could all leave the layout wrong
    # for the rest of the session, with no way back but the hotkey. `verify`
    # costs one `xrandr --query` and issues no RandR call at all unless the
    # geometry actually differs from the intended arrangement, so it is safe to
    # run on a loop.
    #
    # No Environment= block is needed here, unlike the resume unit above: the
    # LightDM session wrapper runs `systemctl --user import-environment
    # DBUS_SESSION_BUS_ADDRESS DISPLAY XAUTHORITY XDG_SESSION_ID` (line 34)
    # before the session starts, so DISPLAY=:0 and XAUTHORITY are already in the
    # user manager's environment. picom.service is the precedent on this host.
    #
    # NOTE: deliberately NOT `wantedBy` graphical-session.target as a *service*.
    # The login apply already ran in sessionCommands, before bspwm, which is the
    # ordering bspwmrc's `bspc monitor` lines depend on; a second apply racing
    # bspwm is the historical "desktops on the wrong screen" failure. Only the
    # timer is pulled in by the target.
    user.services.ganoslal-displays-verify = {
      description = "Verify and correct the ganoslal monitor layout";
      after = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      unitConfig.ConditionEnvironment = "DISPLAY";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${applyDisplays}/bin/ganoslal-displays verify";
      };
    };

    user.timers.ganoslal-displays-verify = {
      description = "Periodically verify the ganoslal monitor layout";
      partOf = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      timerConfig = {
        # First check 30s into the session, once the login apply has settled,
        # then every two minutes. Two minutes is deliberately unhurried: long
        # enough not to fight a game or nvidia-settings that changed the mode on
        # purpose, short enough that a mis-waking monitor fixes itself before it
        # is worth reaching for super + shift + d.
        #
        # To opt out temporarily:
        #   touch "$XDG_RUNTIME_DIR/ganoslal-displays.pause"
        # or, to stop it for the session:
        #   systemctl --user stop ganoslal-displays-verify.timer
        OnActiveSec = "30s";
        OnUnitActiveSec = "2min";
        AccuracySec = "20s";
        Unit = "ganoslal-displays-verify.service";
      };
    };
  };
}
