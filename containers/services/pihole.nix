# Pi-hole run-as-a-service container, ported from dot-spacedock.
# DISABLED by default (not imported by containers/services/default.nix).
#
# ⚠️  Before enabling: the WEBPASSWORD and sync tokens below are placeholders
# carried from the source repo — move them to sops-nix secrets first, and
# confirm the hardcoded LAN IPs (192.168.51.x) match this network.
{
  lib,
  ...
}:
let
  # Local, self-contained config (was configLib.container-config.pihole).
  piholeConfig = import ./pihole-config.nix { inherit lib; };
in
{
  services.resolved = {
    enable = true;
    settings.DNSStubListener = "no";
  };
  systemd.tmpfiles.rules = [
    "d /var/lib/pihole/etc-pihole 0755 root root -"
    "d /var/lib/pihole/etc-dnsmasq.d 0755 root root -"
  ];
  virtualisation.oci-containers = {
    # backend is set by gigpkgs.containers (podman); leave unset here.
    containers = {
      pihole = {
        inherit (piholeConfig)
          image
          autoStart
          volumes
          environment
          ports
          extraOptions
          ;
      };
      # nebula-sync replica is environment-specific (points at another Pi-hole
      # on the LAN and carries a plaintext token). Disabled for the initial
      # single-host bring-up — re-enable + move the token to sops when a second
      # Pi-hole exists.
      # pihole--sync = {
      #   autoStart = true;
      #   image = "ghcr.io/lovelaze/nebula-sync:latest";
      #   environment = {
      #     PRIMARY = "http://192.168.51.3:20720|<token>";
      #     REPLICAS = "http://192.168.51.2:1702|<token>";
      #     CRON = "0 */4 * * *";
      #     FULL_SYNC = "true";
      #     RUN_GRAVITY = "true";
      #     TZ = "America/New_York";
      #     SKIP_API_PASSWORD = "true";
      #   };
      # };
    };
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      53
      1702
    ];
    allowedUDPPorts = [ 53 ];
  };
}
