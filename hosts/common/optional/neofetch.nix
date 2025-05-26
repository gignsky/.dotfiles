{ inputs, config, lib, ... }:
{
  imports = [
    inputs.nufetch.nixosModules.nufetch
  ];
}
