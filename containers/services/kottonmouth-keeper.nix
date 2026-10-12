# kottonmouthband.com keeper -- drains the site's edge queue (Cloudflare D1)
# into SQLite, emails booking requests, and serves the band's admin. Packaged
# as an OCI image by the `kottonmouth` flake input (`packages.<system>
# .keeper-image`), same pattern as avec-moi-app.nix.
#
# Inbound: none from the LAN. The admin is published on loopback only; the
# cloudflared tunnel is its one door in, and a local nginx gate in front of
# it (not Cloudflare Access) does HTTP Basic Auth with one shared band
# password. The keeper's own ADMIN_EMAILS check is intentionally left unset
# below -- it only means anything behind Cloudflare Access, which nothing
# here uses anymore. Outbound: HTTPS to the site and GitHub (and SMTP, once
# SMTP_URL is set).
# If this is down, the public site doesn't notice -- the queue waits in D1.
{
  inputs,
  config,
  pkgs,
  ...
}:
let
  tunnelId = "1a878786-561d-427c-90cd-358f1b82aea4";
  adminPort = 8790;
  # Loopback port nginx listens on, between cloudflared and the keeper.
  gatePort = 8791;
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
    # htpasswd-format line(s), e.g. `admin:$2y$10$...` -- generate with
    # `nix shell nixpkgs#apacheHttpd -c htpasswd -nBC 10 admin`.
    kottonmouth-admin-htpasswd = {
      owner = "nginx";
      restartUnits = [ "nginx.service" ];
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
      NOTIFY_TO = "kottonmouthband@gmail.com";
      NOTIFY_FROM = "Kottonmouth site <keeper@kottonmouthband.com>";
    };
    volumes = [ "/var/lib/kottonmouth-keeper:/data" ];
    ports = [ "127.0.0.1:${toString adminPort}:8790/tcp" ];
  };

  # Basic-auth gate: cloudflared -> nginx (shared password) -> keeper.
  # Loopback only, same trust boundary the keeper already assumed.
  services.nginx = {
    enable = true;
    virtualHosts."kottonmouth-admin-gate" = {
      listen = [
        {
          addr = "127.0.0.1";
          port = gatePort;
        }
      ];
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString adminPort}";
        extraConfig = ''
          auth_basic "G'day Mate, speak friend and enter!";
          auth_basic_user_file ${config.sops.secrets.kottonmouth-admin-htpasswd.path};
        '';
      };
    };
  };

  # Outbound-only tunnel: no ports opened on the home network. Anything not
  # matching the admin hostname gets a 404 from cloudflared itself.
  services.cloudflared = {
    enable = true;
    tunnels.${tunnelId} = {
      credentialsFile = config.sops.secrets.kottonmouth-tunnel.path;
      default = "http_status:404";
      ingress."admin.kottonmouthband.com" = "http://127.0.0.1:${toString gatePort}";
    };
  };
}
