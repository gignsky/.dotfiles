{
  nix = {
    gc = {
      automatic = true;
      dates = "daily";
      persistent = true;
      randomizedDelaySec = "45min";
    };
    optimise = {
      automatic = true;
      dates = [ "daily" ];
      persistent = true;
      randomizedDelaySec = "45min";
    };
  };
}
