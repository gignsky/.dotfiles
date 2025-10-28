_:

{
  # gui stuff

  # configure keymap in x11
  services.displayManager.sddm.enable = true;
  services.xserver = {
    enable = true;
    # displayManager.lightdm.enable = true;
    desktopManager.xfce.enable = true;
    # desktopManager.plasma5.enable = true;
    # resolutions = [
    #   {
    #     x = 1920;
    #     y = 1080;
    #   }
    # ];
  };
}
