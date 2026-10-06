# kottonmouthband.com keeper -- drains the site's edge queue (Cloudflare D1)
# into SQLite, emails booking requests, and serves the band's admin. Packaged
# as an OCI image by the `kottonmouth` flake input (`packages.<system>
# .keeper-image`), same pattern as avec-moi-app.nix.
#
# Inbound: none from the LAN. The admin is published on loopback only, and the
# cloudflared tunnel below is its single door (admin.kottonmouthband.com,
# behind Cloudflare Access). Outbound: HTTPS to the site and GitHub
# (and SMTP, once SMTP_URL is set).
# If this is down, the public site doesn't notice -- the queue waits in D1.
#
# NOT IMPORTED YET -- sops validates at build time, so first:
#   1. sops (`just sops`): add `kottonmouth-keeper-env` and `kottonmouth-tunnel`.
#   2. `cloudflared tunnel create kottonmouth` -> set tunnelId below;
#      `cloudflared tunnel route dns kottonmouth admin.kottonmouthband.com`;
#      Cloudflare Access app on that hostname (email one-time PIN).
#   3. `nix flake update kottonmouth` once kottonmouth's main has keeper-image.
# Then uncomment ./kottonmouth-keeper.nix in services/default.nix and rebuild.
{
  inputs,
  config,
  pkgs,
  ...
}:
let
  # TODO(tunnel): the UUID printed by `cloudflared tunnel create kottonmouth`.
  tunnelId = "1a878786-561d-427c-90cd-358f1b82aea4";
  adminPort = 8790;
  # Matches the image's `User`; owns the state dir on the host.
  uid = "8790";
in
{
  sops.secrets = {
    # KEEPER_TOKEN / GITHUB_TOKEN, as unquoted KEY=value lines. Optional
    # SMTP_URL enables booking emails; until then they wait, owed, in the db.
    # restartUnits: a nixos-rebuild switch doesn't restart a unit just
    # because a secret *file*'s content changed underneath it -- only if
    # the unit definition itself changes. Without these, rotating either
    # secret silently keeps the old value running until something else
    # bounces the service.
    kottonmouth-keeper-env = {
      restartUnits = [ "podman-kottonmouth-keeper.service" ];
    };
    kottonmouth-tunnel = {
      restartUnits = [ "cloudflared-tunnel-${tunnelId}.service" ];
    };
  };

  systemd.tmpfiles.rules = [ "d /var/lib/kottonmouth-keeper 0700 ${uid} ${uid} -" ];

  virtualisation.oci-containers.containers.kottonmouth-keeper = {
    imageFile = inputs.kottonmouth.packages.${pkgs.system}.keeper-image;
    image = "kottonmouth-keeper:latest";
    autoStart = true;
    environmentFiles = [ config.sops.secrets.kottonmouth-keeper-env.path ];
    environment = {
      TZ = "America/New_York";
      EDGE_URL = "https://kottonmouthband.com";
      GITHUB_REPO = "gignsky/kottonmouth";
      GITHUB_BRANCH = "main";
      # Keep in step with the Cloudflare Access policy on the admin hostname.
      # TODO: Wes's address, and anyone else in the band who edits shows.
      ADMIN_EMAILS = "maxwell@giglab.dev";
      NOTIFY_TO = "kottonmouthband@gmail.com";
      NOTIFY_FROM = "Kottonmouth site <keeper@kottonmouthband.com>";
    };
    volumes = [ "/var/lib/kottonmouth-keeper:/data" ];
    ports = [ "127.0.0.1:${toString adminPort}:8790/tcp" ];
  };

  # Outbound-only tunnel: no ports opened on the home network. Anything not
  # matching the admin hostname gets a 404 from cloudflared itself.
  services.cloudflared = {
    enable = true;
    tunnels.${tunnelId} = {
      credentialsFile = config.sops.secrets.kottonmouth-tunnel.path;
      default = "http_status:404";
      ingress."admin.kottonmouthband.com" = "http://127.0.0.1:${toString adminPort}";
    };
  };
}
