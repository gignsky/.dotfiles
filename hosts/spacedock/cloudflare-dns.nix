# DNS for the cloudflared tunnel hostnames, across kottonmouthband.com,
# christinasceramics.com and giglab.dev.
#
# `services.cloudflared.tunnels.<id>.ingress` only tells the tunnel where to
# *send* a hostname's traffic; it never creates the DNS record that makes
# Cloudflare route the hostname to the tunnel in the first place (error 1016
# "Origin DNS error" when it's missing). This unit closes that gap: on every
# switch it upserts a proxied CNAME `<host> -> <tunnel-id>.cfargotunnel.com`
# for every ingress hostname, derived from the merged ingress attrset -- so
# adding an `ingress."foo.kottonmouthband.com"` anywhere gets its DNS for free
# (admin.* from kottonmouth-keeper.nix, dev-admin.* from the -dev file).
#
# Idempotent: records that already match are left alone. It never deletes
# anything, and refuses to overwrite a non-CNAME record at the same name.
#
# Needs the Cloudflare API token at `cloudflare/dns-edit-env` (a
# `CLOUDFLARE_API_TOKEN=...` EnvironmentFile) with Zone -> DNS -> Edit and
# Zone -> Zone -> Read on every zone below. It is DNS-only on purpose: the
# runners' wrangler deploy tokens (kottonmouth/cloudflare-api-token,
# christina-website/beta-env) keep their own, different permissions. A token
# without DNS Edit fails the unit loudly ("Authentication error"); the switch
# itself still completes.
#
# Zones, one unit each: kottonmouthband.com (admin.* from kottonmouth-keeper.nix),
# christinasceramics.com (auth.* from hosts/spacedock/christina-auth.nix, admin.*
# from ../christina/christina-keeper.nix) and giglab.dev (ready-room.* from
# hosts/spacedock/ready-room.nix). Other records in those zones, giglab.dev's
# DDNS ones included, are never touched.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  tunnelId = "1a878786-561d-427c-90cd-358f1b82aea4";
  target = "${tunnelId}.cfargotunnel.com";

  ingressHosts = lib.attrNames config.services.cloudflared.tunnels.${tunnelId}.ingress;
  hostsIn = zone: lib.filter (h: h == zone || lib.hasSuffix ".${zone}" h) ingressHosts;

  upsert = pkgs.writeShellApplication {
    name = "cloudflare-dns-upsert";
    runtimeInputs = [
      pkgs.curl
      pkgs.jq
    ];
    text = ''
      api=https://api.cloudflare.com/client/v4
      auth="Authorization: Bearer $CLOUDFLARE_API_TOKEN"

      # Prints the response body; on an API error, logs Cloudflare's own error
      # list (curl -f would hide it behind a bare "returned error: 403").
      call() { # method path [json-body]
        local out
        out=$(curl -sS -X "$1" -H "$auth" -H "Content-Type: application/json" \
          ''${3:+--data "$3"} "$api$2")
        if ! jq -e '.success' <<<"$out" >/dev/null 2>&1; then
          echo "Cloudflare API $1 $2 failed: $(jq -c '.errors // .' <<<"$out" 2>/dev/null || echo "$out")" >&2
          return 1
        fi
        printf '%s' "$out"
      }

      zone=$1
      shift
      zone_id=$(call GET "/zones?name=$zone" | jq -er '.result[0].id')

      for host in "$@"; do
        want=$(jq -n --arg n "$host" --arg c "${target}" \
          '{type:"CNAME",name:$n,content:$c,proxied:true,ttl:1}')
        existing=$(call GET "/zones/$zone_id/dns_records?name=$host")
        n=$(jq '.result | length' <<<"$existing")

        if [ "$n" -eq 0 ]; then
          call POST "/zones/$zone_id/dns_records" "$want" >/dev/null
          echo "created  $host -> ${target}"
          continue
        fi

        type=$(jq -r '.result[0].type' <<<"$existing")
        if [ "$n" -ne 1 ] || [ "$type" != CNAME ]; then
          echo "REFUSING $host: $n existing record(s), first is $type -- fix by hand" >&2
          failed=1
          continue
        fi

        if jq -e '.result[0] | .content == "${target}" and .proxied == true' \
            <<<"$existing" >/dev/null; then
          echo "ok       $host"
        else
          id=$(jq -r '.result[0].id' <<<"$existing")
          call PUT "/zones/$zone_id/dns_records/$id" "$want" >/dev/null
          echo "updated  $host -> ${target}"
        fi
      done

      exit "''${failed:-0}"
    '';
  };
  # One oneshot per zone: a tunnel can serve hostnames from any zone in its
  # Cloudflare account, and the one DNS token covers them all.
  dnsToken = config.sops.secrets."cloudflare/dns-edit-env".path;

  mkDns =
    { zone, tokenFile }:
    {
      description = "Upsert Cloudflare DNS for the ${zone} tunnel hostnames";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      # The hostname list is baked into ExecStart, so a changed ingress changes
      # the unit and `nixos-rebuild switch` re-runs it.
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        EnvironmentFile = tokenFile;
        # Leading `-`: a failed upsert is logged (journalctl -u <unit>)
        # but doesn't fail the unit, so a DNS/token problem can't make
        # `nixos-rebuild switch` exit non-zero and take the rolling deploy with it.
        ExecStart = "-${lib.getExe upsert} ${lib.escapeShellArgs ([ zone ] ++ hostsIn zone)}";
        DynamicUser = true;
      };
    };
in
{
  sops.secrets."cloudflare/dns-edit-env" = { };

  systemd.services = {
    kottonmouth-dns = mkDns {
      zone = "kottonmouthband.com";
      tokenFile = dnsToken;
    };

    christina-dns = mkDns {
      zone = "christinasceramics.com";
      tokenFile = dnsToken;
    };

    # ready-room.giglab.dev (hosts/spacedock/ready-room.nix). The apex and the
    # DDNS records here are left alone; the upserter only touches the names the
    # tunnel serves, and refuses to overwrite a non-CNAME at one of them.
    giglab-dns = mkDns {
      zone = "giglab.dev";
      tokenFile = dnsToken;
    };
  };
}
