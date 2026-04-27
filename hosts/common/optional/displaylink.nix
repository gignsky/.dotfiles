# DisplayLink USB Graphics support
# Required for USB-based display docks and adapters
#
# DisplayLink devices use the EVDI (Extensible Virtual Display Interface) kernel module
# to create virtual displays that are transmitted over USB.
#
# NOTE: DisplayLink requires proprietary drivers that need manual download and EULA acceptance.
# This configuration enables the EVDI kernel module which is the open-source component.
# For full DisplayLink support, see: https://nixos.wiki/wiki/Displaylink
#
# This configuration:
# - Loads the EVDI kernel module (open source component)
# - Adds modesetting video driver for basic multi-monitor support
# - Provides xrandr commands for manual display configuration
{
  pkgs,
  config,
  ...
}:
{

  services.xserver = {
    # Setup commands for multi-provider displays
    displayManager.sessionCommands = ''
      # Attempt to connect DisplayLink providers to primary GPU
      # These may fail if DisplayLink service isn't running (requires proprietary drivers)
      ${pkgs.xorg.xrandr}/bin/xrandr --setprovideroutputsource 1 0 2>/dev/null || true
      ${pkgs.xorg.xrandr}/bin/xrandr --setprovideroutputsource 2 0 2>/dev/null || true
    '';

    # Use modesetting driver (works with EVDI for basic support)
    videoDrivers = [ "modesetting" ];
  };

  # Useful tools for display configuration
  environment.systemPackages = with pkgs; [
    xorg.xrandr
    autorandr
  ];

  boot = {
    # Load EVDI kernel module for DisplayLink
    # This is the open-source component that creates virtual display devices
    extraModulePackages = [ config.boot.kernelPackages.evdi ];
    kernelModules = [ "evdi" ];
  };

  # NOTE: For full DisplayLink support with proprietary drivers:
  # 1. Download drivers from Synaptics: https://www.synaptics.com/products/displaylink-usb-graphics-software-ubuntu
  # 2. Follow instructions at: https://nixos.wiki/wiki/Displaylink
  # 3. Add displaylink to videoDrivers and environment.systemPackages
}
