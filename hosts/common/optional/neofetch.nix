{ inputs, config, lib, ... }:
{
  imports = [
    inputs.neofetch.nixosModules.default
  ];

  options.username = lib.mkOption {
    type = lib.types.str;
    default = "gig";
  };
}
