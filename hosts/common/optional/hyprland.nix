{
  lib,
  pkgs,
  inputs,
  ...
}:

{
  services.displayManager = {
    ly.enable = true;
    sddm.enable = lib.mkForce false;
    defaultSession = "hyprland";
  };
  #hyperland
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
  };

  services = {
    xserver.enable = true;
  };
}
