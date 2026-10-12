# Use the cache as an extra substituter. Inert on the server itself and while
# the public key is unset.
{ config, lib, ... }:
let
  inherit (config) binaryCache;
  cfg = binaryCache.client;
  active =
    cfg.enable
    && !binaryCache.server.enable
    && binaryCache.url != null
    && binaryCache.publicKey != null;
in
{
  options.binaryCache.client = {
    enable = lib.mkEnableOption "the fleet binary cache as a substituter";

    connectTimeout = lib.mkOption {
      type = lib.types.int;
      default = 3;
      description = ''
        Seconds before giving up on an unreachable cache (e.g. a laptop off
        the LAN). Nix then falls through to the next substituter.
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf active {
      nix.settings = {
        extra-substituters = [ binaryCache.url ];
        extra-trusted-public-keys = [ binaryCache.publicKey ];
        connect-timeout = cfg.connectTimeout;
        # Build locally if a substituted path turns out to be unavailable.
        fallback = true;
      };
    })
    (lib.mkIf (cfg.enable && !binaryCache.server.enable && binaryCache.publicKey == null) {
      warnings = [
        "binaryCache.client is enabled but binaryCache.publicKey is null; not using the cache."
      ];
    })
  ];
}
