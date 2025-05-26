{ inputs, config, lib, ... }:
{
  imports = [
    inputs.neofetch.nixosModules.neofetch
  ];

  config.username = "gig";
}
