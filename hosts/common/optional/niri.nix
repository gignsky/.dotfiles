{ pkgs, ... }:

# Wayland-native alternative to bspwm.nix. Enables niri itself plus the
# display-manager wiring needed to boot straight into it, same autologin
# spirit as bspwm.nix's LightDM setup, but niri needs no `services.xserver`
# at all.
{
  programs.niri.enable = true;

  services.greetd = {
    enable = true;
    settings = {
      # Boots straight into niri as `gig`, no visible greeter.
      initial_session = {
        command = "niri-session";
        user = "gig";
      };
      # Fallback greeter shown if the initial session is ever exited
      # (logout), so another session can still be picked -- same reason
      # bspwm.nix keeps LightDM's greeter enabled alongside autologin.
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --remember --remember-user-session --cmd niri-session";
      };
    };
  };

  # System-level packages required for niri. User-facing tools (launcher,
  # bar, notifications, lock screen, wallpaper) live in home-manager instead,
  # same split bspwm.nix uses.
  environment.systemPackages = with pkgs; [
    tuigreet
  ];
}
