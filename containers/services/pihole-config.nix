# Centralized Pi-hole container config.
#
# Ported from dot-spacedock `lib/container-config/pihole.nix` and kept local to
# this payload so it is self-contained (the old `configLib.container-config`
# indirection is not carried into the fleet dotfiles). Returns the attributes
# consumed by `virtualisation.oci-containers.containers.pihole`.
#
# Deliberately NOT here: the API password. It arrives at runtime through a
# sops-nix rendered env file (`FTLCONF_webserver_api_password`) — see
# ./pihole.nix. Nothing in this file may reach the world-readable nix store
# carrying a secret.
_: {
  # Pinned to match the on-disk database version in
  # /var/lib/pihole/etc-pihole/versions (DOCKER_VERSION 2025.10.3), so the
  # container adopts the existing gravity/FTL DBs with no schema migration.
  # Bump deliberately, not incidentally — and prefer matching the master's
  # version, since nebula-sync expects primary and replica to agree.
  image = "docker.io/pihole/pihole:2025.10.3";
  autoStart = true;
  volumes = [
    "/var/lib/pihole/etc-pihole:/etc/pihole"
    "/var/lib/pihole/etc-dnsmasq.d:/etc/dnsmasq.d"
  ];

  # Pi-hole v6 env naming: `FTLCONF_<section>_<key>`. The v5 names `WEBPASSWORD`
  # and `PIHOLE_DNS_` are gone.
  #
  # ⚠️  Every setting supplied via an FTLCONF_ env var becomes READ-ONLY — it
  # cannot be changed through the web UI, the CLI, or the API. That has teeth
  # here, because nebula-sync clones config from the master over the API:
  #
  #   * `dns_listeningMode` IS pinned, on purpose. A container behind podman NAT
  #     must listen broadly, and read-only means no sync can ever leave this
  #     replica deaf. The cost is that a nebula-sync FULL_SYNC would die on it
  #     (400 bad_request) — which is why ./pihole.nix uses selective sync with
  #     `SYNC_CONFIG_DNS_EXCLUDE=listeningMode`.
  #   * `dns_upstreams` is deliberately NOT pinned. Upstreams are one of the
  #     things we want cloned from the master; pinning them would make the key
  #     read-only and break the sync the same way.
  environment = {
    TZ = "America/New_York";
    FTLCONF_dns_listeningMode = "all";
  };

  ports = [
    # DNS
    "53:53/tcp"
    "53:53/udp"
    # Web admin / API
    "1702:80/tcp"
    # Optional: DHCP — enable only if this Pi-hole should serve DHCP. Note that
    # ./pihole.nix sets SYNC_CONFIG_DHCP=false so `dhcp.active` is never cloned
    # from the master; turning DHCP on here would be a deliberate local choice.
    # "67:67/udp"
  ];
  extraOptions = [
    "--cap-add=NET_ADMIN"
  ];
}
