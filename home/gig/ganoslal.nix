# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  # inputs,
  pkgs,
  lib,
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

  # Discord with CUDA hidden. With the camera on in a call, discord_voice.node
  # encodes through NVENC via libcuda, which maps buffers into nvidia_uvm. On
  # the 580 legacy driver (pinned for the GTX 970, see
  # hosts/ganoslal/nvidia.nix) that path oopses inside nvidia.ko --
  # `_nv0184xxrm` page faults under nvUvmInterfaceDupMemory /
  # FreeDupedHandle, Comm ThreadPoolSingl/ThreadPoolForeg -- and the GPU lock
  # it holds takes the whole desktop down (2026-11-08 x2, 2026-11-09,
  # 2026-11-17). With no visible CUDA device Discord falls back to software
  # H.264 (OpenH264). The .desktop entry runs `Discord` by name, so wrapping
  # both bin names covers launcher starts too.
  discordNoCuda = pkgs.symlinkJoin {
    name = "discord-no-cuda";
    paths = [ pkgs.discord ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      for bin in discord Discord; do
        wrapProgram "$out/bin/$bin" --set CUDA_VISIBLE_DEVICES -1
      done
    '';
  };
in
{
  # You can import other home-manager modules here
  imports = [
    # Or modules exported from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModules.default

    ./home.nix
    ./common/optional/niri.nix # Enable niri window manager configuration (Wayland; pulls in waybar/mako/hyprlock)
    # Previous X11 desktop; swap back together with hosts/ganoslal/default.nix.
    # ./common/optional/bspwm.nix # Enable bspwm window manager configuration
    ./common/optional/thunderbird.nix # WorkMail account, declaratively configured
    ./common/optional/thunderbird-gmail.nix # Personal Gmail accounts, OAuth2
    ./common/optional/thunderbird-fastmail.nix # Column & Coin Fastmail account, OAuth2
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

    # Software H.264 decode for discordNoCuda. With CUDA hidden, Discord can't
    # decode streams on the GPU (Chromium's VA-API path runs on CUDA too) and
    # falls back to OpenH264. That fallback was broken in three ways
    # (2026-11-17), so every stream frame failed with "avcodec_open2 error"
    # and the viewer showed error 2012:
    #   - the native decoder asks for libopenh264-2.5.1-linux64.7.so;
    #   - the JS side only downloads 2.7.0 and, on every start, deletes any
    #     other file in the folder ("OpenH264 cleanup: Deleted unused file");
    #   - Cisco's 2.7.0 binary can't load on NixOS (no libstdc++ on its path).
    # So: link nixpkgs' openh264 (2.6.0, same .so.7 ABI, rpath intact) under
    # the 2.5.1 name and make the folder read-only so cleanup can't unlink
    # it. A Discord-side download into the folder then fails, which is fine.
    activation.discordOpenH264 = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      dir="$HOME/.config/discord/discord_asset_cache/openh264"
      run mkdir -p "$dir"
      run chmod u+w "$dir"
      run ln -sfn ${pkgs.openh264}/lib/libopenh264.so.7 "$dir/libopenh264-2.5.1-linux64.7.so"
      run chmod a-w "$dir"
    '';

    packages = with pkgs; [
      # ytmdesktop
      claude-desktop-with-fhs
      ytmusic
      steam
      plex-desktop
      remmina
      # bitwarden-cli
      bitwarden-desktop
      discordNoCuda
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
