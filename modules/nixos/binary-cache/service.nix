# Shared systemd plumbing for the builder and watcher units (not a module).
{ lib, binaryCache }:
{
  mkService =
    { description, script }:
    {
      inherit description;
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      environment = {
        HOME = binaryCache.stateDir;
      }
      // lib.optionalAttrs (binaryCache.sshKeyFile != null) {
        # Nix fetches git inputs in the client process, so this reaches it.
        GIT_SSH_COMMAND = lib.concatStringsSep " " [
          "ssh -i ${binaryCache.sshKeyFile}"
          "-o IdentitiesOnly=yes"
          "-o StrictHostKeyChecking=accept-new"
          "-o UserKnownHostsFile=${binaryCache.stateDir}/known_hosts"
        ];
      };
      serviceConfig = {
        Type = "oneshot";
        User = binaryCache.user;
        Group = binaryCache.user;
        ExecStart = script;
        # Builds are background work; never starve interactive use.
        Nice = 19;
        IOSchedulingClass = "idle";
      };
    };

  mkTimer = schedule: {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = schedule;
      Persistent = true;
      RandomizedDelaySec = "30s";
    };
  };
}
