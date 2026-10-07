# Harmonia serving this host's /nix/store, signing paths on the fly.
{ config, lib, ... }:
let
  cfg = config.binaryCache.server;
in
{
  options.binaryCache.server = {
    enable = lib.mkEnableOption "the Harmonia binary cache server";

    port = lib.mkOption {
      type = lib.types.port;
      default = 5000;
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    priority = lib.mkOption {
      type = lib.types.int;
      default = 30;
      description = "Substituter priority; lower wins. cache.nixos.org is 40.";
    };

    signingKeyFile = lib.mkOption {
      type = lib.types.str;
      description = ''
        Secret key from `nix key generate-secret`. Read by systemd via
        LoadCredential, so root-only permissions are fine.
      '';
    };

    trustedPushers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Users allowed to `nix copy --to ssh-ng://` unsigned paths into this
        store. Becomes `nix.settings.trusted-users`, which is root-equivalent —
        list only users who already have that level of trust.
      '';
    };

    minFree = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "20G";
      description = ''
        Auto-GC trigger. The cache keeps everything until disk pressure, then
        collects back to `maxFree`; only GC-rooted paths survive.
      '';
    };

    maxFree = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "60G";
    };
  };

  config = lib.mkIf cfg.enable {
    services.harmonia.cache = {
      enable = true;
      signKeyPaths = [ cfg.signingKeyFile ];
      settings = {
        bind = "[::]:${toString cfg.port}";
        inherit (cfg) priority;
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];

    nix.settings = {
      trusted-users = cfg.trustedPushers;
    }
    // lib.optionalAttrs (cfg.minFree != null) { min-free = cfg.minFree; }
    // lib.optionalAttrs (cfg.maxFree != null) { max-free = cfg.maxFree; };
  };
}
