{ pkgs, inputs, ... }:

{
  #hyperland
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
  };

  services = {
    xserver.enable = true;
    displayManager.defaultSession = "hyprland";
  };
}
