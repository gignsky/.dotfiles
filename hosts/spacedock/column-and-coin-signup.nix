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
# Alerts: once a confirmation goes out, one mail goes to you and Lilu together.
#
# Admin page (admin.countthecoin.us, admin/ in that repo): a Cloudflare Worker
# that stays up when spacedock is down. cc-signup reaches it outbound every
# minute (no tunnel route): it applies the removals queued there and sends the
# list back. Sign-in there is the email code, then your Ready Room passphrase
# (Lilu: hers); cc-signup reads the same sops files Ready Room does and sends
# only a salted verifier. Off (adminReady = false) until the Worker exists and
# its sync token sits in nix-secrets at `column-and-coin/admin-sync-token`
# (the same value as the Worker's SYNC_TOKEN secret); then flip and switch.
# After changing a passphrase, restart cc-signup for the page to take it.
#
# Check: curl https://api.countthecoin.us/health
#        sudo cat /var/lib/private/cc-signup/signups.jsonl
#        journalctl -u cc-signup | grep "admin sync"
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

  mailReady = true;
  sender = "maxwell@countthecoin.us";
  lilu = "lilu@countthecoin.us";

  adminReady = false;
  # The Ready Room passphrase files. Lilu's exists only while her Computer is
  # on (ready-room-lilu.nix); without it she can't sign in, and you still can.
  passphrase = name: config.sops.secrets.${name}.path;
  haveLiluPassphrase = config.sops.secrets ? "ready-room-lilu/door-passphrase";
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
    # One mail to you both per signup, once its confirmation has gone out.
    alertTo = [
      sender
      lilu
    ];
  }
  // lib.optionalAttrs adminReady {
    admin = {
      url = "https://admin.countthecoin.us";
      tokenFile = config.sops.secrets."column-and-coin/admin-sync-token".path;
      passphraseFiles = {
        ${sender} = passphrase "ready-room/door-passphrase";
      }
      // lib.optionalAttrs haveLiluPassphrase {
        ${lilu} = passphrase "ready-room-lilu/door-passphrase";
      };
    };
  };

  sops.secrets =
    lib.optionalAttrs mailReady {
      "column-and-coin/smtp-password" = {
        restartUnits = [ "cc-signup.service" ];
      };
    }
    // lib.optionalAttrs adminReady {
      "column-and-coin/admin-sync-token" = {
        restartUnits = [ "cc-signup.service" ];
      };
    };

  services.cloudflared.tunnels.${tunnelId}.ingress."api.countthecoin.us" = {
    service = "http://127.0.0.1:${toString port}";
    path = "^/(notify|health)$";
  };
}
