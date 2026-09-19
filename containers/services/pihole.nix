# Pi-hole run-as-a-service container + nebula-sync replica, on spacedock.
#
# Spacedock is the SLAVE. The master lives on memory-alpha (the TrueNAS box,
# 192.168.51.3, web UI :20720) and is the single source of truth for blocklists,
# groups, clients and DNS config. nebula-sync pulls from it every 4 hours.
#
#   master  192.168.51.3:20720  (memory-alpha / TrueNAS — NOT managed by this repo)
#   replica 192.168.51.2:1702   (this host)
#
# Secrets: the Pi-hole API password is a sops-nix secret (`pihole/api-password`
# in ~/nix-secrets/secrets.yaml) rendered into two env files at runtime. The
# master and the replica share one password by design — nebula-sync authenticates
# against both, and the webserver config section is never synced (see below), so
# there is nothing to drift.
#
# SCOPE: sync-only hot standby. This module publishes :53 and :1702, so the
# replica is *reachable* at 192.168.51.2:53 — but nothing advertises it. No
# host's resolver is pointed here. Repointing the fleet is a deliberate
# follow-up; when it happens, always leave a second nameserver entry so one
# wedged resolver cannot stall a host (see the note on hosts/common/optional/
# dns.nix, added after the master wedged in Sept 2026).
{
  config,
  pkgs,
  ...
}:
let
  piholeConfig = import ./pihole-config.nix { };

  # Pinned, not `:latest`. oci-containers' `pull` default is "missing", so a
  # floating tag would be fetched exactly once and then never updated, while
  # also being unreproducible.
  nebulaSyncImage = "ghcr.io/lovelaze/nebula-sync:v0.11.2";

  masterUrl = "http://192.168.51.3:20720";
  # Reached over the loopback because nebula-sync runs with --network=host: it
  # is in the host netns, so this is identical to curling from the host and is
  # immune to this box's LAN address changing.
  replicaUrl = "http://127.0.0.1:1702";

  apiPassword = config.sops.placeholder."pihole/api-password";
in
{
  # The Pi-hole container owns :53. systemd-resolved's stub listener also wants
  # :53, so the two cannot coexist. resolved is off on this host (NetworkManager
  # drives resolv.conf via resolvconf), and merely setting
  # `services.resolved.settings` while it is disabled is inert — the resolved
  # module gates all of its config behind `mkIf cfg.enable` — i.e. documentation
  # dressed up as protection. Assert instead, so enabling resolved fails the
  # build rather than silently breaking DNS on the box.
  assertions = [
    {
      assertion = !config.services.resolved.enable;
      message = ''
        spacedock's Pi-hole container publishes :53; systemd-resolved's DNS stub
        listener would fight it for the port. Either leave resolved disabled, or
        enable it with `services.resolved.settings.Resolve.DNSStubListener = "no"`
        and drop this assertion.
      '';
    }
  ];

  #################### Secrets ####################

  sops = {
    secrets."pihole/api-password" = { };

    # env-file syntax is unforgiving and silently so. podman's parser
    # (pkg/env.ParseFile) left-trims the line, skips blanks and `#`, splits on
    # the FIRST `=`, and takes the remainder verbatim with no quote stripping.
    # So:
    #   * never put spaces around `=` — the key is not right-trimmed
    #   * never leave trailing whitespace — neither is the value
    #   * never emit a line without `=` — podman reads a bare token as "inherit
    #     from the host env" and DELETES the variable, so a mangled render fails
    #     quietly instead of loudly
    # `|`, `:` and `/` are all literal and must stay unquoted.
    templates = {
      "pihole.env" = {
        content = ''
          FTLCONF_webserver_api_password=${apiPassword}
        '';
        # An FTLCONF_ value is only read when the container starts, so a rotated
        # password needs the container restarted to take effect.
        restartUnits = [ "podman-pihole.service" ];
      };

      # Every nebula-sync setting lives here, not split across the unit's
      # `environment`. FULL_SYNC is `required:"true"` in nebula-sync's envconfig,
      # so an adhoc `podman run --env-file <this>` would crash at startup on a
      # missing variable if the toggles lived elsewhere. One file, one source of
      # truth, works for both the timer and a manual run.
      "nebula-sync.env".content = ''
        PRIMARY=${masterUrl}|${apiPassword}
        REPLICAS=${replicaUrl}|${apiPassword}

        # Selective sync, NOT FULL_SYNC — and this is not a downgrade. FULL_SYNC
        # is definitionally "every SYNC_* on, Webserver/Files off", so the list
        # below is the same sync with two deliberate carve-outs:
        #
        #  1. listeningMode. It is pinned read-only via FTLCONF_ in
        #     ./pihole-config.nix, so PATCHing it returns 400 bad_request.
        #     FULL_SYNC PATCHes the whole `dns` object with a nil filter (see
        #     newFullSyncConfigSettings in nebula-sync's internal/sync/full.go),
        #     so it cannot avoid the key and the entire run aborts after 5
        #     retries.
        #  2. dhcp. A full sync clones `dhcp.active` from the master, which would
        #     turn a standby into a second DHCP server on the LAN.
        FULL_SYNC=false

        # Gravity: the blocklists and the tables that give them meaning.
        SYNC_GRAVITY_GROUP=true
        SYNC_GRAVITY_AD_LIST=true
        SYNC_GRAVITY_AD_LIST_BY_GROUP=true
        SYNC_GRAVITY_DOMAIN_LIST=true
        SYNC_GRAVITY_DOMAIN_LIST_BY_GROUP=true
        SYNC_GRAVITY_CLIENT=true
        SYNC_GRAVITY_CLIENT_BY_GROUP=true
        # A standby that serves no DHCP has no use for the master's leases.
        SYNC_GRAVITY_DHCP_LEASES=false

        # Config sections. The key is `listeningMode`, NOT `dns.listeningMode`:
        # the filter is applied to the already-scoped `dns` sub-object
        # (filterPatchConfigRequest -> configResponse.Get("dns")) and only splits
        # on `.` to descend WITHIN it. Case-sensitive, comma-separated. If a
        # first sync reports `400 ... hint: dns.<key>` for some other
        # host-specific key, append it here.
        SYNC_CONFIG_DNS=true
        SYNC_CONFIG_DNS_EXCLUDE=listeningMode
        SYNC_CONFIG_DHCP=false
        SYNC_CONFIG_NTP=true
        SYNC_CONFIG_RESOLVER=true
        SYNC_CONFIG_DATABASE=true
        SYNC_CONFIG_MISC=true
        SYNC_CONFIG_DEBUG=true

        # Rebuild gravity on the replica once the lists have landed.
        RUN_GRAVITY=true

        # Default is 1s, which is far too tight. The teleporter import restarts
        # FTL on the replica and syncConfigs can fire before its webserver is
        # back (lovelaze/nebula-sync#268, 502 / "invalid sid"); 10s widens the
        # 5-attempt config PATCH window from ~5s to ~50s, and replica auth from
        # ~3s to ~30s.
        CLIENT_RETRY_DELAY_SECONDS=10

        TZ=America/New_York
      '';
    };
  };

  #################### Containers ####################

  virtualisation.oci-containers = {
    # backend is set by gigpkgs.containers (podman); leave unset here.
    containers.pihole = {
      inherit (piholeConfig)
        image
        autoStart
        volumes
        environment
        ports
        extraOptions
        ;
      # A string, not a Nix path literal — `environmentFiles` is
      # `listOf path`-with-absolute-check, which accepts a string and so does
      # NOT copy the rendered secret into the world-readable nix store.
      environmentFiles = [ config.sops.templates."pihole.env".path ];
    };
  };

  systemd = {
    # `- - - -` on purpose: create the directories if missing, but do NOT enforce
    # mode/ownership on what is already there. /var/lib/pihole/etc-pihole holds a
    # ~170 MB tree owned by the in-container pihole user (uid 1000); spelling out
    # `0755 root root` would make systemd-tmpfiles chown all of it on every boot,
    # only for the image's start.sh to chown it straight back.
    tmpfiles.rules = [
      "d /var/lib/pihole/etc-pihole - - - -"
      "d /var/lib/pihole/etc-dnsmasq.d - - - -"
    ];

    # nebula-sync is a batch job, not a daemon, so it is a oneshot + timer rather
    # than an oci-container with CRON set. That is a deliberate departure from
    # the sibling payloads, for three reasons:
    #
    #  * nebula-sync syncs IMMEDIATELY on startup and `Run()` returns the error
    #    if that first sync fails — cron is never installed. As a long-running
    #    container (Restart=on-failure, sdnotify=conmon, so "ready" means "the
    #    container started", not "FTL's API is listening") a cold boot races FTL
    #    opening a 72 MB gravity.db and lands in a restart loop until systemd's
    #    start limit parks the unit in `failed`.
    #  * a timer gives boot slack, automatic retry, and Persistent= to catch runs
    #    missed while the box was off.
    #  * `systemctl start nebula-sync` becomes the on-demand sync (see
    #    `just pihole-sync-now`) with clean per-run logs.
    services.nebula-sync = {
      description = "Sync Pi-hole settings from the master on memory-alpha";
      # Requires, not just After: syncing into a Pi-hole that is not running is
      # pointless, and Requires propagates the master container's failure.
      after = [
        "network-online.target"
        "podman-pihole.service"
      ];
      requires = [ "podman-pihole.service" ];
      wants = [ "network-online.target" ];
      path = [
        config.virtualisation.podman.package
        pkgs.curl
        pkgs.coreutils
      ];

      # The readiness gate. `podman-pihole.service` reports ready as soon as the
      # container starts, which is well before FTL has opened a 72 MB gravity.db
      # and bound its webserver. nebula-sync only retries replica auth
      # AttemptsPostAuth(3) x CLIENT_RETRY_DELAY_SECONDS, so wait for a real
      # HTTP response first. Any status counts — 401 from /api/auth proves the
      # webserver is up, which is all we need.
      preStart = ''
        for _ in $(seq 1 60); do
          code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 ${replicaUrl}/api/auth || true)
          if [ "$code" != "000" ]; then
            echo "Pi-hole API is up (HTTP $code); proceeding with sync."
            exit 0
          fi
          sleep 5
        done
        echo "Pi-hole API did not respond at ${replicaUrl} within 300s; giving up." >&2
        exit 1
      '';

      # --network=host: a short-lived, trusted HTTP client has nothing to gain
      # from a NAT namespace, and host networking keeps podman's published-port
      # hairpin entirely out of the failure surface.
      # --replace: a previous crashed run must not block this one on a name clash.
      script = ''
        exec podman run --rm --replace --name nebula-sync \
          --network=host \
          --env-file ${config.sops.templates."nebula-sync.env".path} \
          ${nebulaSyncImage}
      '';

      serviceConfig = {
        Type = "oneshot";
        # preStart alone can burn 300s, and a first gravity rebuild is slow.
        TimeoutStartSec = "30min";
      };
    };

    timers.nebula-sync = {
      description = "Periodic Pi-hole sync from the master on memory-alpha";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        # Generous boot slack: FTL needs tens of seconds to open the existing
        # gravity DB, and nothing depends on the replica being fresh at t=0.
        OnBootSec = "10min";
        # Matches the old nebula-sync CRON of "0 */4 * * *".
        OnUnitActiveSec = "4h";
        # Catch up on a run missed while the box was powered off.
        Persistent = true;
        RandomizedDelaySec = "5min";
      };
    };
  };

  #################### Firewall ####################

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      53 # DNS
      1702 # Pi-hole web admin / API
    ];
    allowedUDPPorts = [ 53 ];
  };
}
