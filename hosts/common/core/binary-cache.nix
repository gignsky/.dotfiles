# Every host uses the fleet binary cache on spacedock as a substituter (the
# module skips itself on the server). Once a push key exists, every host also
# uploads whatever it builds. See docs/guides/BINARY-CACHE.md.
{
  config,
  lib,
  configLib,
  configVars,
  ...
}:
let
  vars = configVars.binaryCache;
  # Flips on with `pushPublicKey` in vars/binary-cache.nix — set it only after
  # the private half is in nix-secrets, or validateSopsFiles fails the build.
  pushOnBuild = vars.pushPublicKey != null && !config.binaryCache.server.enable;
in
{
  imports = [ (configLib.relativeToRoot "modules/nixos/binary-cache") ];

  sops.secrets = lib.mkIf pushOnBuild { "binary-cache/push-key" = { }; };

  binaryCache = {
    inherit (vars) url publicKey;
    client = {
      enable = true;
      pushOnBuild = lib.mkIf pushOnBuild {
        enable = true;
        host = vars.pushHost;
        inherit (vars) hostKey;
        sshKeyFile = config.sops.secrets."binary-cache/push-key".path;
      };
    };
  };
}
