# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
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
    # ./common/optional/vscode
    # ./cams-countertop.nix
  ];

  home.packages = with pkgs; [
    plex-desktop
    remmina
    youtube-music
    # bitwarden-cli
    # bitwarden-desktop
    discord
    makemkv
    steam
    # anydesk
    # bambu-studio
    inputs.claude-desktop.packages.${system}.claude-desktop
    # inputs.claude-desktop.packages.${system}.claude-desktop-with-fhs # for use if you want MCP
    # servers
  ];

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "25.05";
}
