{ pkgs, ... }:

{
  services = {
    displayManager = {
      # Using LightDM instead of ly
      ly.enable = false;

      # Enable auto-login for user gig
      # Note: This will auto-login every time, even after logout
      # To change sessions, you'll need to select a different session before logging out
      autoLogin = {
        enable = true;
        user = "gig";
      };

      # Default session for auto-login
      defaultSession = "none+bspwm";
    };

    xserver = {
      enable = true;
      windowManager.bspwm.enable = true;

      # LightDM configuration
      displayManager.lightdm = {
        enable = true;
        greeter.enable = true;

        # Configure LightDM behavior
        extraConfig = ''
          [Seat:*]
          greeter-hide-users = false
          greeter-show-manual-login = false
          allow-guest = false
          # Timeout before autologin (0 = immediate)
          autologin-user-timeout = 5
        '';

        # GTK Greeter configuration
        greeters.gtk = {
          enable = true;
          extraConfig = ''
            [greeter]
            # Pre-populate user 'gig' in the greeter
            default-user-image = /home/gig/.face
            hide-user-image = false
            # Show session selector and power menu
            show-indicators = ~session;~power
            show-clock = true
            # Set active monitor for multi-monitor setups
            active-monitor = 0
          '';
        };
      };
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

  # Create a terminal-only session option
  # Access this by logging out and selecting "Terminal Session" from LightDM's session menu
  services.xserver.displayManager.sessionPackages =
    let
      terminalSession = pkgs.writeTextFile {
        name = "xterm-session";
        destination = "/share/xsessions/xterm-session.desktop";
        text = ''
          [Desktop Entry]
          Name=Terminal Session
          Comment=Start with a terminal (no window manager)
          Exec=${pkgs.xterm}/bin/xterm -maximized -e ${pkgs.nushell}/bin/nu
          Type=Application
        '';
        passthru.providedSessions = [ "xterm-session" ];
      };
    in
    [ terminalSession ];
}
