# beta admin for Christina's site -- same keeper as christina-keeper.nix, but
# built off the `rolling` branch and pointed at the beta wrangler environment.
# Modelled on kottonmouth/kottonmouth-keeper-dev.nix; read that for the long
# version of the reasoning.
#
# The image is NOT a flake input: christina-rolling-deploy.service
# (hosts/spacedock/github-runner.nix) builds `keeper-image` off rolling's tip at
# runtime and copies it into podman as `imageRepo`:<version>, so beta deploys
# never rebuild or switch the system.
#
# Not always on (`autoStart = false`): rolling-preview.yml (christina-website)
# starts and stops `podman-christina-keeper-dev.service` through the self-hosted
# runner, running the deploy unit first. On a fresh host the image doesn't exist
# until `systemctl start christina-rolling-deploy` has run once.
#
# Reached through the same cloudflared tunnel as the main keeper, on
# dev-admin.christinasceramics.com, behind the same htpasswd gate.
{
  config,
  lib,
  ...
}:
let
  # Loaded by christina-rolling-deploy.service under its own name -- the image
  # bakes `christina-keeper:<version>`, which would clobber the main keeper's ref.
  imageRepo = "localhost/christina-keeper-dev";
  # Written by the deploy unit: KEEPER_DEV_TAG=<rolling's keeper version>.
  tagEnvFile = "/var/lib/christina-deploy/dev-tag.env";
  tunnelId = "1a878786-561d-427c-90cd-358f1b82aea4";
  adminPort = 8797;
  gatePort = 8798;
  # Matches the image's baked-in `User` (same image as the main keeper).
  uid = "8795";
  authGid = toString config.users.groups.christina-auth.gid;
in
{
  sops.secrets."christina-website/keeper-dev-env" = {
    # KEEPER_TOKEN (= the runner's BETA_KEEPER_TOKEN), GITHUB_TOKEN, PROXY_SECRET
    # (= BETA_ADMIN_PROXY_SECRET); optional CF_ACCOUNT_ID / CF_API_TOKEN.
    restartUnits = [ "podman-christina-keeper-dev.service" ];
  };

  systemd.tmpfiles.rules = [ "d /var/lib/christina-keeper-dev 0700 ${uid} ${uid} -" ];

  virtualisation.oci-containers.containers.christina-keeper-dev = {
    # Expanded by the unit's shell script at start (oci-containers doesn't
    # escape `image`), so the tag follows whatever the last deploy loaded.
    image = "${imageRepo}:\${KEEPER_DEV_TAG:-rolling}";
    # Local-only image; never try a registry.
    pull = "never";
    autoStart = false;
    environmentFiles = [ config.sops.secrets."christina-website/keeper-dev-env".path ];
    environment = {
      TZ = "America/New_York";
      KEEPER_HOST = config.networking.hostName;
      EDGE_URL = "https://beta.christinasceramics.com";
      GITHUB_REPO = "gignsky/christina-website";
      # Throwaway branch: beta admin edits must never reach master via a promote.
      GITHUB_BRANCH = "beta-content";
      # Beta is disposable: clear the keeper DB on every start, then re-seed
      # from main's (MAIN_DB_SEED below).
      RESET_ON_START = "1";
      # Visitor mail goes to the test inbox instead of the visitor.
      MAIL_MODE = "redirect";
      MAIL_REDIRECT_TO = "maxwell@giglab.dev";
      # Served at beta.christinasceramics.com/admin (the beta Worker strips the prefix).
      BASE_PATH = "/admin";
      MAIN_DB_SEED = "/seed/keeper.db";
      INSTAGRAM_TOKEN_FILE = "/auth/token.json";
    };
    volumes = [
      "/var/lib/christina-keeper-dev:/data"
      # Not `:ro`: reading a WAL-mode database needs to touch its -shm file.
      "/var/lib/christina-keeper:/seed"
      "/var/lib/christina-auth:/auth:ro"
    ];
    extraOptions = [ "--group-add=${authGid}" ];
    ports = [ "127.0.0.1:${toString adminPort}:8795/tcp" ];
  };

  systemd.services.podman-christina-keeper-dev.serviceConfig.EnvironmentFile = "-${tagEnvFile}";

  # The image ref above only works while upstream leaves `image` unescaped in
  # the generated script -- fail the build, not the container start, if that changes.
  assertions = [
    {
      assertion = lib.hasInfix " ${imageRepo}:\${KEEPER_DEV_TAG:-rolling}" config.systemd.services.podman-christina-keeper-dev.script;
      message = "christina-keeper-dev: oci-containers now escapes `image`; the version tag needs another way in.";
    }
  ];

  # Same gate as the main keeper (same htpasswd, same identity headers).
  services.nginx = {
    enable = true;
    virtualHosts."christina-admin-dev-gate" = {
      listen = [
        {
          addr = "127.0.0.1";
          port = gatePort;
        }
      ];
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString adminPort}";
        extraConfig = ''
          auth_basic "Christina's Ceramics admin (beta)";
          auth_basic_user_file ${config.sops.secrets."christina-website/admin-htpasswd".path};
          proxy_set_header X-Remote-User $remote_user;
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-Host $host;
        '';
      };
    };
  };

  services.cloudflared.tunnels.${tunnelId}.ingress."dev-admin.christinasceramics.com" =
    "http://127.0.0.1:${toString gatePort}";
}
