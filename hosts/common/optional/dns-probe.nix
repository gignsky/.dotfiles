# DNS latency probe — diagnostic instrumentation.
#
# Background: git push/pull to github.com on this fleet intermittently stalls ~10s.
# `ssh -vvv` located the stall inside name resolution (between "resolving github.com"
# and "Connecting to"), but it does not reproduce on demand, so the cause cannot be
# confirmed from a live session. This timer samples each resolver layer independently
# and logs the timings, so the next stall is captured with enough detail to tell an
# upstream-nameserver problem apart from a local-resolver one.
#
# This module is DIAGNOSTIC and expected to be temporary — remove it once the stall has
# been captured and the root cause addressed.
{
  pkgs,
  lib,
  configLib,
  ...
}:
let
  # NixOS hosts apply `inputs.nixpkgs.overlays.default` (the gigpkgs channel overlay),
  # not this repo's `additions` overlay -- that one is only wired into home-manager in
  # home/gig/home.nix. So `pkgs.dns-probe` does not exist system-side; import the local
  # package set directly, the same way flake.nix builds its `packages` output.
  gigScripts = import (configLib.relativeToRoot "pkgs") { inherit pkgs; };
in
{
  environment.systemPackages = [ gigScripts.dns-probe ];

  systemd.services.dns-probe = {
    description = "DNS resolution latency probe";
    # `network-online` matters: probing before the resolver is configured would log
    # meaningless failures and bury the real event.
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${gigScripts.dns-probe}/bin/dns-probe --log /var/log/dns-probe/dns-probe.log";
      # Needs to write under /var/log; otherwise unprivileged.
      DynamicUser = false;
      LogsDirectory = "dns-probe";
      Nice = 10;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [ "/var/log/dns-probe" ];
      NoNewPrivileges = true;
    };
  };

  systemd.timers.dns-probe = {
    description = "Run the DNS latency probe periodically";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = lib.mkDefault "5min";
      # Spread samples slightly so the probe does not sit in lockstep with other
      # periodic network activity, which could mask or manufacture a correlation.
      RandomizedDelaySec = "30s";
      Unit = "dns-probe.service";
    };
  };

  # Keep the log from growing without bound; it is sampled every 5 minutes.
  services.logrotate.settings.dns-probe = {
    files = [ "/var/log/dns-probe/dns-probe.log" ];
    frequency = "weekly";
    rotate = 4;
    compress = true;
    missingok = true;
    notifempty = true;
  };
}
