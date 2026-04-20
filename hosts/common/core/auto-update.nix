{
  inputs,
  flakePath,
  config,
  ...
}:
let
  flakePath = "/home/gig/.dotfiles"
in 
{
  system.autoUpgrade = {
    enable = true;
    runGarbageCollection = true;
    # randomizedDelaySec = "30min";
    randomizedDelaySec = "0min";
    allowReboot = false;
    #   rebootWindow = {
    #   lower = "03:30";
    #   upper = "05:55";
    # };
    operation = "switch"; # change to "boot" if enabling reboot

    # how often to update
    # dates = "daily";
    dates = "19:38";

    # flake = "github:gignsky/.dotfiles";
    # flake = inputs.self.outPath;
    flake = "${flakePath}#${config.networking.hostName}";
    flags = [
      # "--update-input"
      "--upgrade-all"
      # "nixpkgs"
      "--commit-lock-file"
      "-L" # print build logs
    ];
  };
}
