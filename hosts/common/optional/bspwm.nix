{ pkgs, ... }:

{
  # Enable X server for bspwm
  services.xserver = {
    enable = true;

    # Configure keymap in X11
    xkb = {
      layout = "us";
      variant = "";
    };

    # Enable bspwm window manager
    windowManager.bspwm = {
      enable = true;
    };
  };

  # Use ly display manager for login
  services.displayManager = {
    ly.enable = true;
    defaultSession = "none+bspwm";
  };

  # Install essential packages for bspwm
  environment.systemPackages = with pkgs; [
    # Window manager
    bspwm
    sxhkd # Hotkey daemon for bspwm

    # Terminal emulator
    kitty

    # Application launcher
    rofi

    # System utilities
    polybar # Status bar
    picom # Compositor for transparency and effects
    feh # Image viewer and wallpaper setter
    dunst # Notification daemon

    # File manager
    pcmanfm

    # Screenshots
    scrot

    # System monitoring
    htop

    # Network manager applet
    networkmanagerapplet
  ];

  # Enable the picom compositor service
  # Users can override this in their home-manager config
  # services.picom = {
  #   enable = true;
  # };
}
