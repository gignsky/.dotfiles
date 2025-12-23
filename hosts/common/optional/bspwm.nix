{ pkgs, ... }:

{
  services = {
    displayManager.ly = {
      enable = true;
      settings = {
        # Enable autologin for user gig to bspwm session
        auto_login_user = "gig";
        auto_login_session = "none+bspwm";
        save = true; # Remember session choice

        # Optional: Performance optimizations
        # animation = "none"; # Disable animations for faster boot
        hide_borders = false;
        hide_key_hints = false;
      };
    };
    xserver = {
      enable = true;
      windowManager.bspwm.enable = true;
      # Note: ly display manager is configured with autologin above
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
