# Minimal Home Manager Configuration for NixOS Installer ISO
# This provides a basic configured environment with nushell and gigvim
{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    # Import minimal shell configuration
    ./common/optional/nushell.nix
    
    # Basic git configuration
    ./common/core/git.nix
  ];

  home = {
    username = "gig";
    homeDirectory = "/home/gig";
    stateVersion = "25.05";
  };

  # Essential packages for the installer environment
  home.packages = with pkgs; [
    # Minimal gigvim package for editing
    inputs.gigvim.packages.${system}.minimal
    
    # Essential tools
    tree
    bat
    wget
    curl
    git
  ];

  # Basic programs
  programs = {
    # Enable nushell as the primary shell
    nushell.enable = true;
    
    # Basic shell configuration
    bash.enable = true;
    
    # Directory navigation
    zoxide = {
      enable = true;
      enableNushellIntegration = true;
    };
  };
}