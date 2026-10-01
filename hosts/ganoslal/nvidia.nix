{
  config,
  lib,
  pkgs,
  configVars,
  ...
}:
let
  # Applies the 4-monitor layout. Invoked from three places: sessionCommands at
  # login, a post-resume systemd unit, and an sxhkd binding for manual re-apply.
  # Takes a context argument ("login" | "resume" | anything) used only for
  # logging and for deciding whether to wait for outputs to settle.
  applyDisplays = pkgs.writeShellScriptBin "ganoslal-displays" ''
    set -u
    # Pin the PATH rather than inheriting it. This runs from three different
    # contexts (xsession, a systemd unit, sxhkd), and a minimal PATH would make
    # grep/cut/seq silently produce nothing instead of failing loudly.
    export PATH=${
      lib.makeBinPath [
        pkgs.coreutils
        pkgs.gnugrep
      ]
    }:$PATH
    XRANDR=${pkgs.xrandr}/bin/xrandr
    LOG=/tmp/xrandr-init.log
    CTX="''${1:-manual}"

    log() { echo "ganoslal-displays[$CTX]: $*" >> "$LOG"; }

    # Attach the secondary GPU (GTX 970) to the primary GPU's X screen so its
    # outputs are usable. Provider-name based, not output-name based, so it is
    # unaffected by output renaming.
    $XRANDR --setprovideroutputsource NVIDIA-G0 NVIDIA-0 2>/dev/null || true

    is_connected() {
      $XRANDR --query 2>/dev/null | grep -q "^$1 connected"
    }

    all_present() {
      is_connected DP-2 && is_connected HDMI-0 && is_connected DP-1-1 && is_connected DP-1
    }

    # On resume, outputs can briefly report disconnected while the links
    # retrain. Without this wait the guard below would trip and drop us into
    # the fallback layout, rearranging the desktop for no reason.
    if [ "$CTX" = "resume" ]; then
      for _ in $(seq 1 20); do
        all_present && break
        sleep 0.5
      done
    fi

    # Physical layout:
    #   [HDMI-0] [DP-1-1] [DP-1]   top row, 1920x1080@60 each (5760 wide)
    #            [DP-2]            bottom center, 5120x1440@144
    # DP-2 is centred under the top row: (5760 - 5120) / 2 = 320.
    #
    # Applied as ONE xrandr call so the arrangement lands atomically, but
    # guarded on every output being present first. A single call naming an
    # absent output fails as a whole and silently leaves the previous layout in
    # place — that is exactly how this host ended up mirrored before.
    if all_present; then
      $XRANDR \
        --output DP-2   --primary --mode 5120x1440 --rate 144 --pos 320x1080 \
        --output HDMI-0 --mode 1920x1080 --rate 60 --pos 0x0 \
        --output DP-1-1 --mode 1920x1080 --rate 60 --pos 1920x0 \
        --output DP-1   --mode 1920x1080 --rate 60 --pos 3840x0
      log "applied 4-monitor layout"
    else
      # Unexpected monitor set (cable moved, panel off, driver dropped a GPU).
      # Lay whatever is connected out left-to-right rather than leaving outputs
      # stacked at +0+0, which looks like mirroring.
      log "expected outputs missing, falling back to auto layout"
      prev=""
      for out in $($XRANDR --query 2>/dev/null | grep " connected" | cut -d' ' -f1); do
        if [ -z "$prev" ]; then
          $XRANDR --output "$out" --auto --primary
        else
          $XRANDR --output "$out" --auto --right-of "$prev"
        fi
        prev=$out
      done
    fi

    # Log what X actually ended up with, so display problems can be diagnosed
    # over SSH without a working screen.
    log "complete ($(date))"
    $XRANDR --listmonitors >> "$LOG" 2>&1
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

  # Re-apply the layout on wake.
  #
  # sessionCommands only runs once, at login. After a suspend/resume cycle the
  # driver can drop a mode and nothing puts it back — observed 2026-09-16, when
  # the other monitors woke but the DP-2 ultrawide stayed dark until the next
  # login. A unit that is both `after` and `wantedBy` sleep.target runs on the
  # way back up, not on the way down.
  systemd.services.ganoslal-displays-resume = {
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
}
