{ pkgs, ... }:

{
  imports = [
    ./autorandr.nix
  ];
  services = {
    displayManager = {
      # Using LightDM instead of ly
      ly.enable = false;

      # Auto-login configuration for LightDM
      autoLogin = {
        enable = true;
        user = "gig";
      };

      # Default session (user can still select others at logout)
      defaultSession = "none+bspwm";
    };

    xserver = {
      enable = true;
      windowManager.bspwm.enable = true;

      # LightDM configuration
      displayManager.lightdm = {
        enable = true;
        greeter.enable = true;

        # LightDM auto-login allows logout to switch users/sessions
        # The greeter will show when you explicitly log out
      };
    };
  };

  # System-level packages required for bspwm
  environment.systemPackages = with pkgs; [
    #TODO Look into removing some of these system packages
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
