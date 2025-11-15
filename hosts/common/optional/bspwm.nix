{ configLib, ... }:
let
  bspConfig = configLib.relativeToRoot "hosts/common/resources/bspwm/bspwm.config";
  sxhkdConfig = configLib.relativeToRoot "hosts/common/resources/bspwm/sxhkd.config";
in
{
  services = {
    displayManager.ly.enable = true;
    xserver.windowManager.bspwm = {
      enable = true;
      configFile = bspConfig;
      sxhkd.configFile = sxhkdConfig;
    };
  };
}
