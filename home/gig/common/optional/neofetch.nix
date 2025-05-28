{ inputs, config, lib, ... }:
{
  imports = [
    inputs.nufetch.homeManagerModule.nufetch
  ];

  programs.nufetch = {
    enable = true;
    public_ip = true;
    local_ip = false;
  };
}
