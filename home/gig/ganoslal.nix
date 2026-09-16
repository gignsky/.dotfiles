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
    ./common/optional/bspwm.nix # Enable bspwm window manager configuration
    # ./cams-countertop.nix
  ];
  home = {

    packages = with pkgs; [
      # ytmdesktop
      youtube-music
      steam
      plex-desktop
      remmina
      # bitwarden-cli
      bitwarden-desktop
      discord
      # anydesk
      gpu-viewer
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
