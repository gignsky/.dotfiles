# Pi-hole run-as-a-service container on spacedock (192.168.51.2), the slave to
# the master Pi-hole on memory-alpha (192.168.51.3). Ported from dot-spacedock.
# Web admin: http://192.168.51.2:1702/admin
#
# Before the first switch, add to nix-secrets/secrets.yaml (`just sops`):
#   pihole:
#     master-password: <admin password of the master Pi-hole on memory-alpha>
#     slave-password: <admin password for this slave Pi-hole on spacedock>
# The two may be the same value; each must match its own Pi-hole.
# validateSopsFiles is on, so the build fails until both keys exist. The
# passwords must not contain `|` or `,` (nebula-sync's URL|password separators).
#
# The image is Pi-hole v6, which configures FTL through FTLCONF_* variables;
# the v5 names (WEBPASSWORD, PIHOLE_DNS_) are ignored.
#
# systemd-resolved is deliberately NOT enabled here: nothing on the fleet binds
# :53, and turning resolved on points /etc/resolv.conf at the 127.0.0.53 stub,
# which breaks host DNS when the stub listener is disabled to free the port.
{
  config,
  lib,
  ...
}:
let
  # Local, self-contained config (was configLib.container-config.pihole).
  piholeConfig = import ./pihole-config.nix { inherit lib; };
in
{
  # Only the bare passwords live in sops; the env files the containers read are
  # rendered from them here, so the URLs stay in Nix.
  sops = {
    secrets = {
      "pihole/slave-password" = { };
      "pihole/master-password" = { };
    };
    templates = {
      "pihole.env" = {
        content = ''
          FTLCONF_webserver_api_password=${config.sops.placeholder."pihole/slave-password"}
        '';
        restartUnits = [ "podman-pihole.service" ];
      };
      "pihole-sync.env" = {
        content = ''
          PRIMARY=http://192.168.51.3:20720|${config.sops.placeholder."pihole/master-password"}
          REPLICAS=http://192.168.51.2:1702|${config.sops.placeholder."pihole/slave-password"}
        '';
        restartUnits = [ "podman-pihole--sync.service" ];
      };
    };
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
        environmentFiles = [ config.sops.templates."pihole.env".path ];
      };
      # nebula-sync: pulls everything (Teleporter full sync) from the master
      # Pi-hole on memory-alpha into this slave every 4 hours. PRIMARY (master)
      # and REPLICAS (slave) are nebula-sync's own variable names; they carry
      # the admin passwords, so they come from the sops template above.
      # Settings forced by FTLCONF_* env vars on the pihole container win over
      # synced ones.
      pihole--sync = {
        autoStart = true;
        image = "ghcr.io/lovelaze/nebula-sync:v0.11.3";
        dependsOn = [ "pihole" ];
        environmentFiles = [ config.sops.templates."pihole-sync.env".path ];
        environment = {
          CRON = "0 */4 * * *";
          FULL_SYNC = "true";
          RUN_GRAVITY = "true";
          TZ = "America/New_York";
        };
      };
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
