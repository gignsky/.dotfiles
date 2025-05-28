{ inputs, config, lib, ... }:
{
  # imports = [
  #   inputs.nufetch.nixosModules.nufetch
  # ];

  programs.nufetch = {
    enable = true;
    public_ip = false;
    local_ip = false;
  };
}
