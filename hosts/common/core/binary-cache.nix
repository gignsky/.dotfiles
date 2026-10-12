# Every host uses the fleet binary cache on spacedock as a substituter (the
# module skips itself on the server). See docs/guides/BINARY-CACHE.md.
{ configLib, configVars, ... }:
{
  imports = [ (configLib.relativeToRoot "modules/nixos/binary-cache") ];

  binaryCache = {
    inherit (configVars.binaryCache) url publicKey;
    client.enable = true;
  };
}
