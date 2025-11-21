{ configLib, ... }:
let
  bspConfig = configLib.relativeToRoot "hosts/common/resources/bspwm/bspwm.config";
  sxhkdConfig = configLib.relativeToRoot "hosts/common/resources/bspwm/sxhkd.config";
in
{
  imports = [ (configLib.relativeToRoot "hosts/common/optional/ly.nix") ];
  services.xserver.windowManager.bspwm = {
    enable = true;
    configFile = bspConfig;
    sxhkd.configFile = sxhkdConfig;
  };
}
