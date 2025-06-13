{ ... }:

{
  # gui stuff

  # configure keymap in x11
  services.displayManager.sddm.enable = true;
  services.xserver = {
    enable = true;
    desktopManager.plasma5.enable = true;
    xkb.layout = "us";
    xkb.variant = "";
    resolutions = [
      {
        x = 1920;
        y = 1080;
      }
    ];
  };
}
