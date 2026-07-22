# Centralized Pi-hole container config.
#
# Ported from dot-spacedock `lib/container-config/pihole.nix` and kept local to
# this payload so it is self-contained (the old `configLib.container-config`
# indirection is not carried into the fleet dotfiles). Returns the oci-container
# attributes plus pre-formatted podman flag strings for adhoc use.
{ lib, ... }:
let
  # The core attributes of the Pi-hole container
  coreConfig = {
    # NixOS oci-containers attributes
    image = "docker.io/pihole/pihole:2025.10.3";
    autoStart = true;
    volumes = [
      "/var/lib/pihole/etc-pihole:/etc/pihole"
      "/var/lib/pihole/etc-dnsmasq.d:/etc/dnsmasq.d"
    ];
    environment = {
      WEBPASSWORD = "password";
      TZ = "America/New_York";
      # DNSMASQ_LISTENING = "all";
      PIHOLE_DNS_ = "1.1.1.1;8.8.8.8";
      FTLCONF_dns_listeningMode = "all";
    };
    ports = [
      # DNS
      "53:53/tcp"
      "53:53/udp"
      # Web Admin
      "1702:80/tcp"
      # Optional: DHCP - enable if pihole handles dhcp
      # "67:67/udp"
    ];
    extraOptions = [
      "--cap-add=NET_ADMIN"
    ];
  };

  # Helper to convert list-based options (ports/volumes) into podman command
  # strings, for running the same container adhoc.
  formatOptions = config: {
    podmanVolumes = builtins.concatStringsSep " " (builtins.map (v: "--volume ${v}") config.volumes);
    podmanPorts = builtins.concatStringsSep " " (builtins.map (p: "--publish ${p}") config.ports);
    podmanEnv = lib.concatStringsSep " " (
      lib.mapAttrsToList (n: v: "--env ${n}=${v}") config.environment
    );
    podmanExtraOptions = builtins.concatStringsSep " " config.extraOptions;
  };
in
coreConfig // (formatOptions coreConfig)
