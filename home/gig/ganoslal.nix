# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  # inputs,
  pkgs,
  ...
}:
let
  # Shared with the render-drm-device pin below and with
  # hosts/ganoslal/niri-render-gpu.nix, which holds niri back until it exists.
  renderNode = "/dev/dri/by-path/pci-0000:2d:00.0-render";

  # Safety net for that ordering. If niri still started on the GTX 970 (pin
  # missed, PCI address changed, ...) the only symptom is a shimmer on every
  # screen and an idle 3060 Ti -- easy to live with for days without knowing
  # why (2026-11-08). Say so instead. The sleep gives mako, spawned alongside
  # this, time to own the notification bus name.
  checkRenderGpu = pkgs.writeShellScript "niri-check-render-gpu" ''
    ${pkgs.coreutils}/bin/sleep 5
    want=$(${pkgs.coreutils}/bin/readlink -f ${renderNode})
    got=$(${pkgs.systemd}/bin/journalctl --user -b -t niri -o cat --no-pager \
      --grep 'using as the render node' \
      | ${pkgs.coreutils}/bin/tail -n1 \
      | ${pkgs.gnugrep}/bin/grep -o '/dev/dri/renderD[0-9]*')
    [ -n "$got" ] && [ "$got" = "$want" ] && exit 0
    ${pkgs.util-linux}/bin/logger -t niri-check-render-gpu "niri renders on ''${got:-unknown}, expected $want (3060 Ti)"
    ${pkgs.libnotify}/bin/notify-send -u critical "niri is on the wrong GPU" \
      "Rendering on ''${got:-unknown} instead of the 3060 Ti ($want). Expect flicker; log out and back in."
  '';
in
{
  # You can import other home-manager modules here
  imports = [
    # Or modules exported from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModules.default

    ./home.nix
    ./common/optional/niri.nix # Enable niri window manager configuration (Wayland; pulls in waybar/mako/swaylock)
    # Previous X11 desktop; swap back together with hosts/ganoslal/default.nix.
    # ./common/optional/bspwm.nix # Enable bspwm window manager configuration
    ./common/optional/thunderbird.nix # WorkMail account, declaratively configured
    ./common/optional/thunderbird-gmail.nix # Personal Gmail accounts, OAuth2
    ./common/optional/minecraft-create.nix # Prism Launcher + instance matching the spacedock Create server
    # ./cams-countertop.nix
  ];

  # 4-monitor layout, same physical arrangement as the bspwm-era xrandr
  # script in hosts/ganoslal/nvidia.nix:
  #
  #   [HDMI-A-2] [DP-1]    [DP-4]     top row, 1920x1080@60 each
  #              [DP-5]               bottom, 5120x1440@144, centred
  #
  # These are KMS connector names, NOT the X/RandR names from nvidia.nix
  # (HDMI-0 / DP-1-1 / DP-1 / DP-2). Mapped from /sys/class/drm EDIDs on
  # 2026-10-24:
  #   card0 (RTX 3060 Ti, 2d:00.0)  HDMI-A-2  22N1     top left
  #                                 DP-4      22N1     top right
  #                                 DP-5      49Q1R    ultrawide
  #   card1 (GTX 970, 23:00.0)      DP-1      IPS235   top centre
  # The two 22N1 panels have byte-identical EDIDs, so they can only be told
  # apart by connector -- swapping their cables swaps them on screen.
  #
  # The ultrawide's 5120x1440 modes are only in its DisplayID extension
  # block. If niri falls back to 1920x1080 on DP-5 (check `niri msg
  # outputs`), force it with `mode custom=true "5120x1440@144"`.
  #
  # Modes name no refresh rate on purpose: niri then takes the highest one
  # the resolution offers (60 on the 1080p panels, 144 on the ultrawide)
  # instead of depending on an exact millihertz match.
  #
  # render-drm-device pins rendering to the 3060 Ti, mirroring the X BusID
  # pin in nvidia.nix: the kernel numbers the 970 renderD128, so it would
  # otherwise be picked as the primary GPU. by-path keeps this stable
  # across boots; the 970's monitor is fed by a cross-GPU copy. niri only
  # tries the pin once at startup and silently falls back if the node is not
  # there yet -- see hosts/ganoslal/niri-render-gpu.nix and checkRenderGpu.
  niriHostConfig = ''
    spawn-at-startup "${checkRenderGpu}"

    // WezTerm on Wayland waits for a configure event with a zero size before
    // it will draw, so a concrete niri width can leave it blank. It hit this
    // host's 5120-wide DP-5 but not the 1920-wide DP-1. An empty
    // default-column-width lets WezTerm pick its own size. ganoslal only: on
    // merlin it made new terminals sometimes open short until resized.
    window-rule {
        match app-id=r#"^org\.wezfurlong\.wezterm$"#
        default-column-width {}
    }

    output "HDMI-A-2" {
        mode "1920x1080"
        position x=0 y=0
    }

    output "DP-1" {
        mode "1920x1080"
        position x=1920 y=0
    }

    output "DP-4" {
        mode "1920x1080"
        position x=3840 y=0
    }

    output "DP-5" {
        mode "5120x1440"
        scale 1
        position x=320 y=1080
        focus-at-startup

        // niri's stock 50% column is a bit narrow on the ultrawide; 60% is
        // where Mod+Ctrl+L x2 (+5% each) used to land it by hand.
        layout {
            default-column-width { proportion 0.6; }
        }
    }

    debug {
        render-drm-device "${renderNode}"
    }
  '';

  home = {

    packages = with pkgs; [
      # ytmdesktop
      claude-desktop-with-fhs
      ytmusic
      steam
      plex-desktop
      remmina
      # bitwarden-cli
      bitwarden-desktop
      discord
      # anydesk
      gpu-viewer
      # AnyDesk re-uploaded the 8.1.0 tarball in place (2026-11-03), breaking
      # nixpkgs' pinned hash. Drop this override once nixpkgs catches up.
      (anydesk.overrideAttrs (old: {
        src = fetchurl {
          inherit (old.src) urls;
          hash = "sha256-zS5P2eyTHZY7cBW8mQ2Q6M0lXcx9VZZTtpG3Bb6u7IQ=";
        };
      }))
    ];

    # NOTE: the autorandr profiles that used to live here were removed — they
    # pinned output names (DP-2, HDMI-0) that no longer exist, and two of this
    # host's panels share a byte-identical EDID so autorandr can't fingerprint
    # them apart. The desktop environment owns the monitor layout instead.
    # Stale copies survive a switch; clean up once with:
    #   rm -rf ~/.config/autorandr/ganoslal-4-monitor ~/.config/autorandr/ganoslal-only-ultra

    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    stateVersion = "25.05";
  };
}
