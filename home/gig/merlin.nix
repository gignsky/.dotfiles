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
    ./common/optional/thunderbird.nix # WorkMail account, declaratively configured
    ./common/optional/thunderbird-gmail.nix # Personal Gmail accounts, OAuth2
    ./common/optional/minecraft-create.nix
    # ./common/optional/vscode
    # ./cams-countertop.nix
  ];

  # Merlin is a single-display laptop; the docked-monitor case was already
  # unused (commented out) in the bspwm-era resource file, so it's not
  # ported. niri's auto scale picked 1.5 (1706x1066 logical) on this
  # 2560x1600 panel, which made text too big -- pin it lower. Try 1.0 for
  # even smaller, 1.25 -> 1.33 -> 1.5 for larger.
  niriHostConfig = ''
    output "eDP-1" {
        scale 1.25
    }
  '';

  home.packages = with pkgs; [
    plex-desktop
    remmina
    ytmusic
    # bitwarden-cli
    # bitwarden-desktop
    discord
    audacity
    # makemkv
    steam
    # anydesk
    # bambu-studio
    claude-desktop
    obsidian
    gnumeric
  ];

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "25.05";
}
