# beta.kottonmouthband.com keeper -- same service as kottonmouth-keeper.nix,
# but tracking the `rolling` branch instead of `main`, behind the beta
# wrangler environment instead of production. The image is NOT a flake
# input: kottonmouth-rolling-deploy.service (hosts/spacedock/github-runner.nix)
# builds `keeper-image` off rolling's tip at runtime and copies it into podman
# as `imageRepo`:<version> (the keeper's Cargo.toml version on rolling, the
# same tag the main keeper's image carries), so beta deploys never rebuild or
# switch the system and can't revert whatever roll branch spacedock is
# currently on.
#
# Unlike the main keeper, this one is NOT always on: `autoStart = false`.
# It only runs while `rolling` differs from `main` -- there's nothing to
# preview once a roll has been promoted. rolling-preview.yml (in the
# kottonmouth repo) starts and stops `podman-kottonmouth-keeper-dev.service`
# via a self-hosted Actions runner on this host (see ./github-runner.nix),
# running the deploy unit first so the image matches rolling's current HEAD.
#
# On a fresh host (or after `podman image prune -a`) the image doesn't exist
# until the deploy unit has run once: `systemctl start kottonmouth-rolling-deploy`.
#
# Inbound: none from the LAN, same as the main keeper -- loopback only,
# reached through the *same* cloudflared tunnel on a second hostname. No
# second tunnel/credentials needed; NixOS merges `services.cloudflared.
# tunnels.<id>.ingress` across files.
{
  config,
  lib,
  ...
}:
let
  # Loaded by kottonmouth-rolling-deploy.service under its own name -- the
  # image bakes `kottonmouth-keeper:<version>`, which is the main keeper's
  # ref whenever rolling and main share a version, so a plain `podman load`
  # would clobber it.
  imageRepo = "localhost/kottonmouth-keeper-dev";
  # Written by the deploy unit: KEEPER_DEV_TAG=<rolling's keeper version>.
  tagEnvFile = "/var/lib/kottonmouth-deploy/dev-tag.env";
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
    # KEEPER_TOKEN / GITHUB_TOKEN (+ CF_ACCOUNT_ID / CF_API_TOKEN for email) for the beta environment -- distinct from
    # the main keeper's, so this only ever drains kottonmouth-edge-beta.
    "kottonmouth/kottonmouth-keeper-dev-env" = {
      restartUnits = [ "podman-kottonmouth-keeper-dev.service" ];
    };
  };

  systemd.tmpfiles.rules = [ "d /var/lib/kottonmouth-keeper-dev 0700 ${uid} ${uid} -" ];

  virtualisation.oci-containers.containers.kottonmouth-keeper-dev = {
    # Expanded by the unit's shell script at start (oci-containers doesn't
    # escape `image`), so the tag follows whatever the last deploy loaded;
    # `rolling` is only a fallback for before the first tagged deploy.
    image = "${imageRepo}:\${KEEPER_DEV_TAG:-rolling}";
    # Local-only image; never try a registry.
    pull = "never";
    # Started/stopped by rolling-preview.yml based on rolling-vs-main
    # divergence, not on boot.
    autoStart = false;
    environmentFiles = [ config.sops.secrets."kottonmouth/kottonmouth-keeper-dev-env".path ];
    environment = {
      TZ = "America/New_York";
      EDGE_URL = "https://beta.kottonmouthband.com";
      GITHUB_REPO = "gignsky/kottonmouth";
      # Throwaway branch, not `rolling`: beta admin edits (shows, settings)
      # must never reach main via a promote. rolling-preview.yml recreates it
      # from rolling + main's data on every deploy and deletes it on teardown.
      GITHUB_BRANCH = "beta-content";
      # Beta is disposable: clear the keeper DB on every start, then re-seed
      # from main's (MAIN_DB_SEED below).
      RESET_ON_START = "1";
      # Email: visitor mail (welcome, booking confirmation) goes to the test
      # inbox instead of the visitor; band alerts still reach the band, marked
      # [BETA], so a real booking made here by accident is not lost. Needs
      # CF_ACCOUNT_ID / CF_API_TOKEN in the sops env file; band alert
      # recipients default to keeper@kottonmouthband.com (editable in the admin).
      MAIL_MODE = "redirect";
      MAIL_REDIRECT_TO = "maxwell@giglab.dev";
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

  systemd.services.podman-kottonmouth-keeper-dev.serviceConfig.EnvironmentFile = "-${tagEnvFile}";

  # The image ref above only works while upstream leaves `image` unescaped in
  # the generated script -- fail the build, not the container start, if that
  # ever changes.
  assertions = [
    {
      assertion = lib.hasInfix " ${imageRepo}:\${KEEPER_DEV_TAG:-rolling}" config.systemd.services.podman-kottonmouth-keeper-dev.script;
      message = "kottonmouth-keeper-dev: oci-containers now escapes `image`; the version tag needs another way in.";
    }
  ];

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
