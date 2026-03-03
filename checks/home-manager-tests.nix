{
  lib,
  self,
}:
let
  homeManagerChecks = lib.mapAttrs' (name: cfg: {
    name = "homeManager-${name}";
    value = cfg.activationPackage;
  }) self.homeConfigurations;
in
homeManagerChecks
