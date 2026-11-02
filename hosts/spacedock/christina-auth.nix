# Always-on "Log in with Instagram" for Christina's site, so swapping the
# Instagram account is a browser login at https://auth.christinasceramics.com/
# auth/instagram instead of a dev tunnel, and the token renews itself.
#
# christina-auth.service runs scripts/instagram-auth-server.mjs from the
# christina-website flake input (the `master` branch, so it changes only once
# a roll is promoted and the input updated). It is dependency-free Node, so nothing is
# built on the box. It writes the 60-day token to
# /var/lib/christina-auth/token.json; the beta workflow
# (github-runner.nix) reads that file at build time, so no sops commit or
# rebuild is needed when the token changes. christina-auth-refresh.timer
# extends it weekly; Instagram refuses a refresh inside 24 hours of issue and
# the script skips a token that fresh.
#
# Reached through the same cloudflared tunnel as kottonmouth's keeper (NixOS
# merges tunnels.<id>.ingress across files), restricted to /auth/instagram.
# The login is behind HTTP basic auth (AUTH_USER / AUTH_PASSWORD).
#
# Needs the sops secret `christina-website/auth-env`, systemd EnvironmentFile
# syntax, with INSTAGRAM_APP_ID, INSTAGRAM_APP_SECRET, INSTAGRAM_REDIRECT_URI
# (https://auth.christinasceramics.com/auth/instagram/callback, registered in
# the Meta app), AUTH_USER and AUTH_PASSWORD. The proxied CNAME
# `auth.christinasceramics.com -> <tunnel-id>.cfargotunnel.com` is upserted on
# every switch by the christina-dns unit in
# containers/services/kottonmouth/kottonmouth-dns.nix.
{
  config,
  inputs,
  pkgs,
  ...
}:
let
  # Same tunnel as kottonmouth-keeper.nix. The tunnel credentials belong to the
  # Cloudflare account that owns kottonmouthband.com; a tunnel can only serve
  # hostnames in zones of that account.
  tunnelId = "1a878786-561d-427c-90cd-358f1b82aea4";
  port = 8794;
  script = "${inputs.christina-website}/scripts/instagram-auth-server.mjs";
  node = "${pkgs.nodejs_22}/bin/node";
  tokenFile = "/var/lib/christina-auth/token.json";

  hardening = {
    User = "christina-auth";
    Group = "christina-auth";
    # 0750 so the beta runner (SupplementaryGroups in github-runner.nix) can read token.json (0640).
    StateDirectory = "christina-auth";
    StateDirectoryMode = "0750";
    NoNewPrivileges = true;
    ProtectSystem = "strict";
    ProtectHome = true;
    PrivateTmp = true;
    PrivateDevices = true;
    ProtectKernelTunables = true;
    ProtectControlGroups = true;
    RestrictSUIDSGID = true;
  };
in
{
  sops.secrets."christina-website/auth-env" = {
    restartUnits = [ "christina-auth.service" ];
  };

  users.users.christina-auth = {
    isSystemUser = true;
    group = "christina-auth";
  };
  # Pinned so the keeper containers can join the group by number
  # (`--group-add`) and read token.json.
  users.groups.christina-auth.gid = 8794;

  # update-users-groups never renumbers a group that already exists, so a box
  # that made christina-auth before the pin keeps its old dynamic gid and the
  # keepers get "Permission denied" on /auth/token.json. Move the group (and
  # the state dir's files) to the pinned gid, and restart the service so the
  # tokens it writes from now on carry it too. A no-op once they match.
  system.activationScripts.christina-auth-gid = {
    deps = [ "users" ];
    text = ''
      want=${toString config.users.groups.christina-auth.gid}
      have=$(${pkgs.getent}/bin/getent group christina-auth | cut -d: -f3)
      if [ -n "$have" ] && [ "$have" != "$want" ]; then
        echo "christina-auth: moving gid $have -> $want"
        ${pkgs.shadow}/bin/groupmod -g "$want" christina-auth
        if [ -d /var/lib/christina-auth ]; then
          ${pkgs.findutils}/bin/find /var/lib/christina-auth -gid "$have" -exec chgrp -h "$want" {} +
        fi
        if [ -d /run/systemd/system ]; then
          systemctl try-restart christina-auth.service || true
        fi
      fi
    '';
  };

  systemd = {
    services.christina-auth = {
      description = "Log in with Instagram for christinasceramics.com";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      environment = {
        HOST = "127.0.0.1";
        PORT = toString port;
        TOKEN_FILE = tokenFile;
      };
      serviceConfig = hardening // {
        ExecStart = "${node} ${script}";
        EnvironmentFile = config.sops.secrets."christina-website/auth-env".path;
        Restart = "on-failure";
        RestartSec = "10s";
      };
    };

    services.christina-auth-refresh = {
      description = "Extend the stored Instagram token for christinasceramics.com";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      environment.TOKEN_FILE = tokenFile;
      serviceConfig = hardening // {
        Type = "oneshot";
        ExecStart = "${node} ${script} --refresh";
      };
    };

    timers.christina-auth-refresh = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
    };
  };

  services.cloudflared.tunnels.${tunnelId}.ingress."auth.christinasceramics.com" = {
    service = "http://127.0.0.1:${toString port}";
    path = "^/auth/instagram";
  };
}
