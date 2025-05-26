{ inputs, config, lib, ... }:
{
  imports = [
    inputs.nufetch.nixosModules.neofetch
  ];
}
