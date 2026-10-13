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

    pushUser = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "cache-push";
        description = "Account clients' post-build hooks push as (see `client.pushOnBuild`).";
      };

      authorizedKeys = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = ''
          SSH public keys allowed to push as `name`. The account is only created
          when this is non-empty. Each key is forced to `nix-daemon --stdio`, so
          it can do nothing but talk to the store — but it is still a trusted
          user (unsigned paths), so give it a dedicated key.
        '';
      };
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
    users.users = lib.mkIf (cfg.pushUser.authorizedKeys != [ ]) {
      ${cfg.pushUser.name} = {
        isSystemUser = true;
        group = cfg.pushUser.name;
        # The forced command runs via the login shell; nologin would block it.
        useDefaultShell = true;
        openssh.authorizedKeys.keys = map (
          key: ''restrict,command="${config.nix.package}/bin/nix-daemon --stdio" ${key}''
        ) cfg.pushUser.authorizedKeys;
      };
    };
    users.groups = lib.mkIf (cfg.pushUser.authorizedKeys != [ ]) { ${cfg.pushUser.name} = { }; };

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
      trusted-users =
        cfg.trustedPushers ++ lib.optional (cfg.pushUser.authorizedKeys != [ ]) cfg.pushUser.name;
    }
    // lib.optionalAttrs (cfg.minFree != null) { min-free = cfg.minFree; }
    // lib.optionalAttrs (cfg.maxFree != null) { max-free = cfg.maxFree; };
  };
}
