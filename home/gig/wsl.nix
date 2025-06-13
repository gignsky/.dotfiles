# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{ inputs
, outputs
, pkgs
, lib
, configLib
, config
, ...
}:
{
  imports = [
    ./home.nix
    ./common/optional/vscode
    # ./common/optional/vim.nix
  ];

  _module.args.isWSL = true;

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      # outputs.overlays.modifications
      outputs.overlays.unstable-packages
    ];
  };

  home.packages = with pkgs; [
    unstable.yt-dlp
    mosh
    qdirstat
  ];

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.05";
}
