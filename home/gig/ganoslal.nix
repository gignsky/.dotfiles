# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  # inputs,
  pkgs,
  ...
}:
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
  # across boots; the 970's monitor is fed by a cross-GPU copy.
  niriHostConfig = ''
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
    }

    debug {
        render-drm-device "/dev/dri/by-path/pci-0000:2d:00.0-render"
    }
  '';

  home = {

    packages = with pkgs; [
      # ytmdesktop
      # Upstream only rewraps bin/; point the .desktop Exec lines at the FHS wrapper too
      (symlinkJoin {
        name = "claude-desktop-with-fhs";
        paths = [ claude-desktop-with-fhs ];
        postBuild = ''
          f=$out/share/applications/com.anthropic.Claude.desktop
          src=$(readlink -f "$f"); rm "$f"
          sed "s|^Exec=[^ ]*/bin/claude-desktop|Exec=$out/bin/claude-desktop|" "$src" > "$f"
        '';
      })
      ytmusic
      steam
      plex-desktop
      remmina
      # bitwarden-cli
      bitwarden-desktop
      discord
      # anydesk
      gpu-viewer
      anydesk
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
