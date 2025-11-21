{
  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      persistent = true;
      randomizedDelaySec = "45min";
    };
    optimise = {
      automatic = true;
      dates = [ "weekly" ];
      persistent = true;
      randomizedDelaySec = "45min";
    };
  };
}
