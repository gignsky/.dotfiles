{ pkgs, ... }:

{
  imports = [
    ./ly.nix # Import ly display manager configuration
  ];

  services = {
    xserver = {
      enable = true;
      windowManager.bspwm.enable = true;
      # ly display manager is configured in separate ly.nix file
    };
  };

  # System-level packages required for bspwm
  environment.systemPackages = with pkgs; [
    bspwm # Binary space partitioning window manager
    sxhkd # Simple X hotkey daemon
    rofi # Application launcher and window switcher
    feh # Fast image viewer and wallpaper setter
    xclip # X11 clipboard utilities
    maim # Screenshot utility
    xdotool # X11 automation tool
    picom # Compositor for transparency and effects
  ];
}
