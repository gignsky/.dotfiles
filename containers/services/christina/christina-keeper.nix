# admin.christinasceramics.com -- christina-keeper, the admin for Christina's
# site. Packaged as an OCI image by the `christina-website` flake input
# (`packages.<system>.keeper-image`), the same pattern as kottonmouth-keeper.nix
# and modelled on it: see docs/keeper.md in that repo.
#
# The input follows `master`, updated by hand with `nix flake update
# christina-website` once a roll has been promoted, like kottonmouth's `main`.
# The beta twin of this keeper is christina-keeper-dev.nix.
#
# Inbound: none from the LAN. The keeper is published on loopback only; the
# cloudflared tunnel (shared with kottonmouth's admin and auth.christinasceramics.com)
# is its one door in, and a local nginx gate in front of it does HTTP Basic
# Auth with one shared password. nginx forwards the htpasswd user as
# X-Remote-User (overwriting anything a client sent), which the admin reports
# and uses as the signed-in identity. ADMIN_EMAILS is deliberately unset: it
# only means anything behind Cloudflare Access.
#
# Until `master` carries a keeper-image (and the lock is updated), this file
# defines nothing and warns, so an unrelated rebuild still goes through.
{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  # `or` guards the whole chain: `master` has no `packages` output until the keeper is promoted.
  keeperImage =
    inputs.christina-website.packages.${pkgs.stdenv.hostPlatform.system}.keeper-image or null;
  # Same tunnel as kottonmouth-keeper.nix and christina-auth.nix; this file
  # only adds one more ingress hostname to it. The christina-dns unit
  # (kottonmouth/kottonmouth-dns.nix) upserts the proxied CNAME for it.
  tunnelId = "1a878786-561d-427c-90cd-358f1b82aea4";
  adminPort = 8795;
  # Loopback port nginx listens on, between cloudflared and the keeper.
  gatePort = 8796;
  # Matches the image's `User`; owns the state dir on the host.
  uid = "8795";
  # Pinned in hosts/spacedock/christina-auth.nix so containers can join the
  # group (and read token.json) by number.
  authGid = toString config.users.groups.christina-auth.gid;
  htpasswd = config.sops.secrets."christina-website/admin-htpasswd".path;
in
# mkMerge/mkIf, not `// optionalAttrs`: the condition reads `pkgs`, and the set of
# option names a module defines must not depend on config, or Nix recurses forever.
lib.mkMerge [
  {
    warnings = lib.optional (keeperImage == null) ''
      christina-keeper: the christina-website input (${inputs.christina-website.rev or "dirty"})
      has no packages.${pkgs.stdenv.hostPlatform.system}.keeper-image, so
      admin.christinasceramics.com is not configured. Promote the keeper roll
      to `master`, then `nix flake update christina-website`.
    '';

    # Also used by the dev gate (christina-keeper-dev.nix), so defined whether
    # or not the main image exists yet.
    # htpasswd-format line(s), e.g. `christina:$2y$10$...` -- generate with
    # `nix shell nixpkgs#apacheHttpd -c htpasswd -nBC 10 christina`. The user
    # name is what the status page shows as "Signed in as", so one line per
    # person if that should mean something.
    sops.secrets."christina-website/admin-htpasswd" = {
      owner = "nginx";
      restartUnits = [ "nginx.service" ];
    };
  }
  (lib.mkIf (keeperImage != null) {
    # KEEPER_TOKEN / GITHUB_TOKEN as unquoted KEY=value lines; optional
    # CF_ACCOUNT_ID + CF_API_TOKEN (Cloudflare Email Service) turn the emails on.
    # restartUnits: rotating the file's content doesn't restart the unit alone.
    sops.secrets."christina-website/keeper-env" = {
      restartUnits = [ "podman-christina-keeper.service" ];
    };

    systemd.tmpfiles.rules = [ "d /var/lib/christina-keeper 0700 ${uid} ${uid} -" ];

    virtualisation.oci-containers.containers.christina-keeper = {
      imageFile = keeperImage;
      image = "${keeperImage.imageName}:${keeperImage.imageTag}";
      autoStart = true;
      environmentFiles = [ config.sops.secrets."christina-website/keeper-env".path ];
      environment = {
        TZ = "America/New_York";
        # What the status page calls the machine; otherwise it would show the
        # container ID. KEEPER_BIND is baked into the image (0.0.0.0:8795).
        KEEPER_HOST = config.networking.hostName;
        EDGE_URL = "https://christinasceramics.com";
        GITHUB_REPO = "gignsky/christina-website";
        GITHUB_BRANCH = "master";
        # Written by christina-auth.service; the status row and gallery feed read it.
        INSTAGRAM_TOKEN_FILE = "/auth/token.json";
      };
      volumes = [
        "/var/lib/christina-keeper:/data"
        "/var/lib/christina-auth:/auth:ro"
      ];
      # token.json is 0640 root:christina-auth (dir 0750); join the group by number.
      extraOptions = [ "--group-add=${authGid}" ];
      ports = [ "127.0.0.1:${toString adminPort}:8795/tcp" ];
    };

    # Basic-auth gate: cloudflared -> nginx (shared password) -> keeper.
    # Loopback only, same trust boundary as kottonmouth's gate.
    services.nginx = {
      enable = true;
      virtualHosts."christina-admin-gate" = {
        listen = [
          {
            addr = "127.0.0.1";
            port = gatePort;
          }
        ];
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString adminPort}";
          extraConfig = ''
            auth_basic "Christina's Ceramics admin";
            auth_basic_user_file ${htpasswd};
            # Who the gate let in, for the keeper's "Signed in as" row.
            proxy_set_header X-Remote-User $remote_user;
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-Host $host;
          '';
        };
      };
    };

    # One more hostname on the shared outbound-only tunnel; the tunnel's
    # credentials and 404 default are declared in kottonmouth-keeper.nix.
    services.cloudflared.tunnels.${tunnelId}.ingress."admin.christinasceramics.com" =
      "http://127.0.0.1:${toString gatePort}";
  })
]
