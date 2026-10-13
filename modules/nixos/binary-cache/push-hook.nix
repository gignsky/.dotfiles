# Upload everything this host builds to the cache, whatever started the build
# (`nix build`, `nix flake check`, rebuilds, roll-flow gates, devShells…).
#
# Nix runs `post-build-hook` as root after every derivation it builds, and the
# build waits for it — a slow or failing hook stalls or aborts the build. So
# the hook only appends `$OUT_PATHS` to a queue file. A path unit starts
# `cache-drain` when the queue changes, and a timer retries what an unreachable
# cache bounced. Pushed paths are not GC-rooted on the server; they stay until
# disk pressure evicts them (roots come from `cache-push`).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config) binaryCache;
  cfg = binaryCache.client.pushOnBuild;
  queueDir = "/var/lib/binary-cache-push";

  hook = pkgs.writeShellScript "binary-cache-post-build-hook" ''
    # Must be quick and must never fail: Nix aborts the build otherwise.
    printf '%s\n' $OUT_PATHS >> ${queueDir}/queue 2>/dev/null
    exit 0
  '';

  storeUri = "ssh-ng://${cfg.user}@${cfg.host}?ssh-key=${cfg.sshKeyFile}";
in
{
  options.binaryCache.client.pushOnBuild = {
    enable = lib.mkEnableOption "uploading every locally built path to the cache";

    host = lib.mkOption {
      type = lib.types.str;
      example = "192.168.1.2";
      description = "SSH address of the cache server.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "cache-push";
      description = "Push user on the server (see `binaryCache.server.pushUser`).";
    };

    sshKeyFile = lib.mkOption {
      type = lib.types.str;
      description = "Root-readable private key for `user` on the server.";
    };

    hostKey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "ssh-ed25519 AAAA…";
      description = ''
        The server's SSH host key, pinned in /etc/ssh/ssh_known_hosts. Without
        it the push is refused: root has no interactive way to accept it.
      '';
    };

    batchDelay = lib.mkOption {
      type = lib.types.int;
      default = 30;
      description = ''
        Seconds to wait after the queue changes before uploading, so a
        burst of builds goes up in one copy instead of one per derivation.
      '';
    };

    retryInterval = lib.mkOption {
      type = lib.types.str;
      default = "15min";
      description = "How often to retry paths that failed to upload.";
    };
  };

  config = lib.mkIf (cfg.enable && !binaryCache.server.enable) {
    nix.settings.post-build-hook = hook;

    programs.ssh.knownHosts = lib.mkIf (cfg.hostKey != null) {
      binary-cache = {
        hostNames = [ cfg.host ];
        publicKey = cfg.hostKey;
      };
    };

    systemd = {
      tmpfiles.rules = [ "d ${queueDir} 0700 root root -" ];

      paths.binary-cache-push = {
        description = "Upload newly built paths to the binary cache";
        wantedBy = [ "paths.target" ];
        pathConfig.PathChanged = "${queueDir}/queue";
      };

      timers.binary-cache-push = {
        description = "Retry binary cache uploads";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "5min";
          OnUnitInactiveSec = cfg.retryInterval;
        };
      };

      services.binary-cache-push = {
        description = "Upload queued build outputs to the binary cache";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        environment.NIX_SSHOPTS = "-o ConnectTimeout=3 -o BatchMode=yes";
        serviceConfig = {
          Type = "oneshot";
          ExecStartPre = "${pkgs.coreutils}/bin/sleep ${toString cfg.batchDelay}";
          ExecStart = lib.escapeShellArgs [
            (lib.getExe' binaryCache.package.cache-drain "cache-drain")
            "--queue-dir"
            queueDir
            "--to"
            storeUri
          ];
          Nice = 19;
          IOSchedulingClass = "idle";
        };
      };
    };
  };
}
