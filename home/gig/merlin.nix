# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  # inputs,
  outputs
, pkgs
, ...
}:
{
  # You can import other home-manager modules here
  imports = [
    # Or modules exported from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModules.default

    ./home.nix
    # ./common/optional/vscode
    # ./cams-countertop.nix
  ];

  home.packages = with pkgs; [
    plex-media-player
    remmina
    # bitwarden-cli
    bitwarden-desktop
    discord
    # anydesk
  ];

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "25.05";
}
