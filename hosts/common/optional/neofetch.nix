{ inputs, ... }:
{
  imports = [
    inputs.nufetch.nixosModules.nufetch
  ];

  programs.nufetch = {
    enable = true;
    public_ip = true;
    local_ip = false;
  };
}
