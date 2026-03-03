{ lib, self }:
let
  assertAllHostsHaveVmTest =
    configs:
    let
      missing = lib.filterAttrs (_: config: (config.config.system.build.vmTest or null) == null) configs;
    in
    if missing != { } then
      throw "\\nSome nixosConfigurations are missing a vmTest!\\nOffending hosts: ${builtins.concatStringsSep ", " (builtins.attrNames missing)}\\nEach host must define config.system.build.vmTest."
    else
      true;

  nixosTests =
    assert assertAllHostsHaveVmTest self.nixosConfigurations;
    lib.filterAttrs (_: v: v != null) (
      lib.mapAttrs' (name: config: {
        name = "nixosTest-${name}";
        value = config.config.system.build.vmTest or null;
      }) self.nixosConfigurations
    );
in
nixosTests
