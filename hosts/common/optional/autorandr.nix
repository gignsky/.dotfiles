{ pkgs, ... }:
{
  services.autorandr = {
    enable = true;

    #host specific profiles are loaded from the similarlly named home-manager file

    # Optional: automatically switch profiles on monitor changes
    hooks = {
      postswitch = {
        "notify-user" = ''
          ${pkgs.libnotify}/bin/notify-send "Autorandr" "Switched to profile $AUTORANDR_CURRENT_PROFILE"
        '';
        # Restart BSPWM to reconfigure desktops
        "reload-bspwm" = ''
          ${pkgs.bspwm}/bin/bspc wm -r
        '';
      };
    };
  };
}
