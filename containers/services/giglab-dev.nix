# giglab.dev on spacedock.
#
# Container: the spec giglab.dev publishes as `containers.<sys>.giglab`,
# discovered by gigpkgs' inputMan (containers/inputs/giglab-dev.nix in gigpkgs)
# and run through the gigpkgs container engine. Updates arrive via gigpkgs:
# `inputman update giglab-dev` there -> channel -> this flake's nixpkgs input.
# The spec binds 127.0.0.1:8800 itself. Interim image (static-web-server over
# the Astro build): no state, no secrets, so no volumes/environmentFiles yet.
#
# Front door: router 80/443 -> Nginx Proxy Manager on TrueNAS, which terminates
# TLS (wildcard Let's Encrypt cert for giglab.dev + *.giglab.dev, Cloudflare
# DNS-01) and forwards every giglab.dev name over plain HTTP to spacedock:1776.
# This nginx routes by Host, so a new <name>.giglab.dev demo site is one more
# virtualHost below -- nothing changes on the router or TrueNAS. Unknown names
# get a 404. Port 1776 is reachable only from TrueNAS.
{ lib, ... }:
let
  frontDoorPort = 1776;
  sitePort = 8800;
  truenasIp = "192.168.51.3";

  listen = [
    {
      addr = "0.0.0.0";
      port = frontDoorPort;
    }
  ];
in
{
  gigpkgs.containers.fromInputs.giglab.enable = true;

  services.nginx = {
    enable = true;
    # Log the visitor's address, not TrueNAS's.
    commonHttpConfig = ''
      set_real_ip_from ${truenasIp};
      real_ip_header X-Forwarded-For;
    '';

    virtualHosts = {
      "giglab.dev" = {
        inherit listen;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString sitePort}";
          recommendedProxySettings = true;
        };
      };

      "www.giglab.dev" = {
        inherit listen;
        # Explicit https: TLS ends at TrueNAS, so $scheme here would be http.
        locations."/".return = "301 https://giglab.dev$request_uri";
      };

      # Catch-all for any other *.giglab.dev name until a vhost claims it.
      "giglab-dev-unknown" = {
        inherit listen;
        default = true;
        serverName = "_";
        locations."/".return = "404";
      };
    };
  };

  # Only TrueNAS's proxy may reach the front door (iptables backend).
  networking.firewall.extraCommands = lib.mkAfter ''
    iptables -A nixos-fw -p tcp -s ${truenasIp} --dport ${toString frontDoorPort} -j nixos-fw-accept
  '';
}
