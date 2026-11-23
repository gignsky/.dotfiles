# Column & Coin signup server: the backend behind the notify form on the
# countthecoin.us coming soon page (and the same page in the Tauri app).
#
# cc-signup (server/ in gignsky/column-and-coin, via that flake's
# nixosModules.cc-signup) keeps each address in
# /var/lib/private/cc-signup/signups.jsonl and mails a "you're on the list"
# confirmation through Fastmail SMTP. It is a small Rust build (plain release
# profile, no LTO), nothing like Ready Room's.
#
# Reached through the same cloudflared tunnel as kottonmouth-keeper.nix,
# christina-auth.nix and ready-room.nix (NixOS merges tunnels.<id>.ingress
# across files), restricted to /notify and /health. A tunnel only serves
# hostnames in its own Cloudflare account's zones, so countthecoin.us must be
# in that account. The proxied CNAME api.countthecoin.us -> <tunnel>.cfargotunnel.com
# is upserted on every switch by countthecoin-dns (cloudflare-dns.nix), once
# `cloudflare/dns-edit-env`'s token has DNS Edit and Zone Read on the zone.
#
# Mail is off (mailReady = false) until countthecoin.us sends through Fastmail
# (the Fastmail runbook). Until then signups are kept and their confirmations
# wait; they go out within minutes of turning mail on. To turn it on: put a
# Fastmail app password with SMTP access, bare on one line, in nix-secrets at
# `column-and-coin/smtp-password`, set mailReady = true and switch. Not before
# Fastmail can send as countthecoin.us: each address gets five tries.
#
# Check: curl https://api.countthecoin.us/health
#        sudo cat /var/lib/private/cc-signup/signups.jsonl
{
  config,
  inputs,
  lib,
  ...
}:
let
  # Same tunnel as kottonmouth-keeper.nix, christina-auth.nix and ready-room.nix.
  tunnelId = "1a878786-561d-427c-90cd-358f1b82aea4";
  port = 7480;

  mailReady = false;
  sender = "maxwell@countthecoin.us";
in
{
  imports = [ inputs.column-and-coin.nixosModules.cc-signup ];

  services.cc-signup = {
    enable = true;
    listen = "127.0.0.1:${toString port}";
  }
  // lib.optionalAttrs mailReady {
    smtp.user = sender;
    smtp.passwordFile = config.sops.secrets."column-and-coin/smtp-password".path;
    from = "Column & Coin <${sender}>";
    # A short note to you on each new signup.
    ownerNotify = sender;
  };

  sops.secrets = lib.optionalAttrs mailReady {
    "column-and-coin/smtp-password" = {
      restartUnits = [ "cc-signup.service" ];
    };
  };

  services.cloudflared.tunnels.${tunnelId}.ingress."api.countthecoin.us" = {
    service = "http://127.0.0.1:${toString port}";
    path = "^/(notify|health)$";
  };
}
