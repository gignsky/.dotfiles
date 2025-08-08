# GanosLal Home Manager Configuration
# This is the home manager configuration for user gig on ganosLal host
{
  inputs,
  outputs,
  configLib,
  ...
}:
{
  imports = [
    # Base home configuration
    ./home.nix
    
    # Host-specific configurations can be added here
    # ./common/optional/desktop-apps.nix
    # ./common/optional/development-tools.nix
  ];

  # Host-specific home manager configurations
  home = {
    username = "gig";
    homeDirectory = "/home/gig";
    stateVersion = "25.05";
  };

  # Enable nushell and shell aliases
  programs.nushell.enable = true;
  
  # Host-specific configurations
  # programs.git.userEmail = "gig@ganosLal.local";
}