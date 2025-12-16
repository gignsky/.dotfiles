# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  # inputs,
  outputs,
  system,
  # , config,
  pkgs,
  ...
}:
{
  # You can import other home-manager modules here
  imports = [
    # Or modules exported from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModules.default
    ./home.nix
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Custom packages are available as flake packages instead of overlay
      # outputs.overlays.additions  # Removed to avoid circular dependencies
      # outputs.overlays.modifications
      outputs.overlays.unstable-packages
    ];
  };

  home.packages = with pkgs; [
    # inputs.flake-iter.packages.${system}.default
    unstable.yt-dlp
    mosh
    qdirstat
  ];

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.05";
}
