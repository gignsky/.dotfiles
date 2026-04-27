# DisplayLink USB Graphics support
# Required for USB-based display docks and adapters
#
# DisplayLink devices use the EVDI (Extensible Virtual Display Interface) kernel module
# to create virtual displays that are transmitted over USB.
#
# This configuration:
# - Enables the DisplayLink service
# - Loads the EVDI kernel module
# - Adds displaylink driver to video drivers
{ pkgs, ... }:
{

  services.xserver = {
    # Enable DisplayLink service
    displayManager.sessionCommands = ''
      ${pkgs.xorg.xrandr}/bin/xrandr --setprovideroutputsource 1 0
      ${pkgs.xorg.xrandr}/bin/xrandr --setprovideroutputsource 2 0
    '';

    # Add DisplayLink to video drivers
    videoDrivers = [
      "displaylink"
      "modesetting"
    ];

    # Enable DisplayLink service
    displayManager.setupCommands = ''
      ${pkgs.xorg.xrandr}/bin/xrandr --setprovideroutputsource 1 0 || true
      ${pkgs.xorg.xrandr}/bin/xrandr --setprovideroutputsource 2 0 || true
    '';
  };

  # Ensure the displaylink package is available in system environment
  environment.systemPackages = with pkgs; [
    displaylink
  ];

  boot = {
    # Load EVDI kernel module for DisplayLink
    extraModulePackages = with pkgs; [ evdi ];
    kernelModules = [ "evdi" ];
  };
}
