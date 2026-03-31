# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  # inputs,
  pkgs,
  configLib,
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

    file = {
      # 4 monitor setup
      ".config/autorandr/ganoslal-4-monitor/config" = {
        source = configLib.relativeToRoot "home/gig/common/resources/autorandr/ganoslal/ganoslal-4-monitor/config";
        executable = true;
      };
      ".config/autorandr/ganoslal-4-monitor/setup" = {
        source = configLib.relativeToRoot "home/gig/common/resources/autorandr/ganoslal/ganoslal-4-monitor/setup";
        executable = true;
      };

      #only ultrawide setup
      ".config/autorandr/ganoslal-only-ultra/config" = {
        source = configLib.relativeToRoot "home/gig/common/resources/autorandr/ganoslal/ganoslal-only-ultra/config";
        executable = true;
      };
      ".config/autorandr/ganoslal-only-ultra/setup" = {
        source = configLib.relativeToRoot "home/gig/common/resources/autorandr/ganoslal/ganoslal-only-ultra/setup";
        executable = true;
      };
    };

    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    stateVersion = "25.05";
  };
}
