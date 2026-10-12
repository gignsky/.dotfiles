# binary-cache — self-hosted Nix binary cache for a small fleet.
#
# One host runs Harmonia (`server`) and serves its own /nix/store; every other
# host lists it as a substituter (`client`). The server's store is populated
# three ways:
#   - `builder`: a timer that builds a fixed set of flake refs (packages,
#     host closures) and keeps them rooted.
#   - `watch`:   a timer that polls git remotes and builds every matching
#     branch/tag head as soon as it lands, whoever pushed it.
#   - pushes:    clients `nix copy` what they built (see `cache-push`).
#
# Deliberately host-agnostic: no hostnames, addresses, repos or secret
# backends live in here — the consuming config passes all of that in. Laid out
# to match gigpkgs `modules/nixos/` so extraction is a copy + namespace rename;
# see docs/guides/BINARY-CACHE.md.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.binaryCache;
in
{
  imports = [
    ./server.nix
    ./client.nix
    ./builder.nix
    ./watch.nix
  ];

  options.binaryCache = {
    url = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "http://192.168.1.2:5000";
      description = "URL clients use to reach the cache.";
    };

    publicKey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "cache-1:AAAA…=";
      description = ''
        Public half of the server's signing key (`nix key convert-secret-to-public`).
        While null, clients add no substituter, so the module can be rolled out
        before the key exists.
      '';
    };

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/binary-cache";
      description = "State + GC-root directory shared by the builder and watcher.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "binary-cache";
      description = "System user the builder and watcher run their builds as.";
    };

    sshKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Optional SSH private key (readable by `user`) for fetching private
        `git+ssh://` flake inputs, e.g. a read-only GitHub deploy key.
      '';
    };

    package = lib.mkOption {
      type = lib.types.attrsOf lib.types.package;
      default = pkgs.callPackage ./package.nix { };
      defaultText = lib.literalExpression "pkgs.callPackage ./package.nix { }";
      readOnly = true;
      internal = true;
      description = "The cache-build / cache-watch / cache-push scripts.";
    };
  };

  config = lib.mkIf (cfg.builder.enable || cfg.watch.enable) {
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.user;
      home = cfg.stateDir;
      createHome = true;
    };
    users.groups.${cfg.user} = { };
  };
}
