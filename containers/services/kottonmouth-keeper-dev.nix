# beta.kottonmouthband.com keeper -- same service as kottonmouth-keeper.nix,
# but tracking the `rolling` branch instead of `main`, behind the beta
# wrangler environment instead of production. Packaged from the
# `kottonmouth-rolling` flake input (`packages.<system>.keeper-image`, same
# derivation as the main keeper, built off a different ref).
#
# Unlike the main keeper, this one is NOT always on: `autoStart = false`.
# It only runs while `rolling` differs from `main` -- there's nothing to
# preview once a roll has been promoted. rolling-preview.yml (in the
# kottonmouth repo) starts and stops `podman-kottonmouth-keeper-dev.service`
# via a self-hosted Actions runner on this host (see ./github-runner.nix),
# refreshing the `kottonmouth-rolling` flake input and switching first so
# the running image always matches rolling's current HEAD.
#
# Inbound: none from the LAN, same as the main keeper -- loopback only,
# reached through the *same* cloudflared tunnel on a second hostname. No
# second tunnel/credentials needed; NixOS merges `services.cloudflared.
# tunnels.<id>.ingress` across files.
{
  inputs,
  config,
  pkgs,
  ...
}:
let
  # Same tunnel as kottonmouth-keeper.nix -- this file only adds one more
  # ingress hostname to it.
  tunnelId = "1a878786-561d-427c-90cd-358f1b82aea4";
  adminPort = 8792;
  gatePort = 8793;
  # Matches the image's baked-in `User` (same image as the main keeper,
  # just built off a different ref) -- NOT the host port above.
  uid = "8790";
in
{
  sops.secrets = {
    # KEEPER_TOKEN / GITHUB_TOKEN for the beta environment -- distinct from
    # the main keeper's, so this only ever drains kottonmouth-edge-beta.
    "kottonmouth/kottonmouth-keeper-dev-env" = {
      restartUnits = [ "podman-kottonmouth-keeper-dev.service" ];
    };
  };

  systemd.tmpfiles.rules = [ "d /var/lib/kottonmouth-keeper-dev 0700 ${uid} ${uid} -" ];

  virtualisation.oci-containers.containers.kottonmouth-keeper-dev = {
    imageFile = inputs.kottonmouth-rolling.packages.${pkgs.stdenv.hostPlatform.system}.keeper-image;
    # keeper-image always bakes the tag `kottonmouth-keeper:latest`, the same
    # as the main keeper's image (it's the same package attribute, just built
    # off a different flake input/ref) -- `image` has to match what the
    # pre-start load actually tagged, or podman can't find it locally and
    # tries (and fails) to pull it from a registry instead. See
    # kottonmouth-keeper.nix for the same pattern.
    image = "kottonmouth-keeper:latest";
    # Started/stopped by rolling-preview.yml based on rolling-vs-main
    # divergence, not on boot.
    autoStart = false;
    environmentFiles = [ config.sops.secrets."kottonmouth/kottonmouth-keeper-dev-env".path ];
    environment = {
      TZ = "America/New_York";
      EDGE_URL = "https://beta.kottonmouthband.com";
      GITHUB_REPO = "gignsky/kottonmouth";
      GITHUB_BRANCH = "rolling";
      NOTIFY_TO = "kottonmouthband@gmail.com";
      NOTIFY_FROM = "Kottonmouth beta <keeper@kottonmouthband.com>";
      # Served at beta.kottonmouthband.com/admin: the beta Worker proxies
      # /admin/* here, stripping the prefix, so links must be emitted with it.
      # PROXY_SECRET (must equal the Worker's ADMIN_PROXY_SECRET) goes in the
      # kottonmouth-keeper-dev-env sops file, not here.
      BASE_PATH = "/admin";
      # On every start, import main's subscribers/bookings/RSVPs (read-only;
      # beta rows win; never written back).
      MAIN_DB_SEED = "/seed/keeper.db";
    };
    volumes = [
      "/var/lib/kottonmouth-keeper-dev:/data"
      # Not `:ro`: reading a WAL-mode database needs to touch its -shm file.
      # The keeper opens the file with SQLite `mode=ro`, so it can't write rows.
      "/var/lib/kottonmouth-keeper:/seed"
    ];
    ports = [ "127.0.0.1:${toString adminPort}:8790/tcp" ];
  };

  # Same basic-auth gate pattern as the main keeper, reusing its htpasswd
  # secret -- one shared band password for both admins.
  services.nginx.virtualHosts."kottonmouth-admin-dev-gate" = {
    listen = [
      {
        addr = "127.0.0.1";
        port = gatePort;
      }
    ];
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString adminPort}";
      extraConfig = ''
        auth_basic "G'day Mate, speak friend and enter! (beta)";
        auth_basic_user_file ${config.sops.secrets."kottonmouth/kottonmouth-admin-htpasswd".path};
      '';
    };
  };

  services.cloudflared.tunnels.${tunnelId}.ingress."dev-admin.kottonmouthband.com" =
    "http://127.0.0.1:${toString gatePort}";
}
