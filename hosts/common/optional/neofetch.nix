{ inputs, config, lib, ... }:
{
  programs.nufetch = {
    enable = true;
    public_ip = true;
    local_ip = true;
  };
}
