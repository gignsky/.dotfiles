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

  environment.systemPackages = with pkgs; [
    kitty
    rofi-wayland # runner for starting programs ad-hoc
  ];

  services = {
    xserver.enable = true;
  };
}
