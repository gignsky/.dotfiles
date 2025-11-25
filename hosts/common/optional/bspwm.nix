{ pkgs, ... }:

{
  services = {
    xserver = {
      enable = true;
      windowManager.bspwm.enable = true;
      # Note: ly display manager is configured elsewhere (xfce.nix)
      # This provides bspwm as an additional session option
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
