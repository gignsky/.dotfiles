# admin.christinasceramics.com -- christina-keeper, the admin for Christina's
# site. Packaged as an OCI image by the `christina-website` flake input
# (`packages.<system>.keeper-image`), the same pattern as kottonmouth-keeper.nix
# and modelled on it: see docs/keeper.md in that repo.
#
# The input follows `rolling`, so the admin changes when a roll graduates, not
# when it is promoted to master. Roll 1 is a status page proving the path
# works (build, host, uptime, who the gate let in, which Cloudflare data centre
# the tunnel came through); nothing on the public site calls it, so if this is
# down visitors see nothing.
#
# Inbound: none from the LAN. The keeper is published on loopback only; the
# cloudflared tunnel (shared with kottonmouth's admin and auth.christinasceramics.com)
# is its one door in, and a local nginx gate in front of it does HTTP Basic
# Auth with one shared password. nginx forwards the htpasswd user as
# X-Remote-User, which the keeper's "Signed in as" row reports. ADMIN_EMAILS
# is deliberately unset: it only means anything behind Cloudflare Access.
#
# Until a roll carrying keeper/ graduates into `rolling` and the lock is
# updated (`nix flake update christina-website`), the input has no
# keeper-image; this file then defines nothing and warns, so an unrelated
# rebuild still goes through.
{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  # `or` guards the whole chain: the current `rolling` has no `packages` output at all.
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
  htpasswd = config.sops.secrets."christina-website/admin-htpasswd".path;
in
# mkMerge/mkIf, not `// optionalAttrs`: the condition reads `pkgs`, and the set of
# option names a module defines must not depend on config, or Nix recurses forever.
lib.mkMerge [
  {
    warnings = lib.optional (keeperImage == null) ''
      christina-keeper: the christina-website input (${inputs.christina-website.rev or "dirty"})
      has no packages.${pkgs.stdenv.hostPlatform.system}.keeper-image, so
      admin.christinasceramics.com is not configured. Graduate the keeper roll
      into `rolling`, then `nix flake update christina-website`.
    '';
  }
  (lib.mkIf (keeperImage != null) {
    # htpasswd-format line(s), e.g. `christina:$2y$10$...` -- generate with
    # `nix shell nixpkgs#apacheHttpd -c htpasswd -nBC 10 christina`. The user
    # name is what the status page shows as "Signed in as", so one line per
    # person if that should mean something.
    sops.secrets."christina-website/admin-htpasswd" = {
      owner = "nginx";
      restartUnits = [ "nginx.service" ];
    };

    systemd.tmpfiles.rules = [ "d /var/lib/christina-keeper 0700 ${uid} ${uid} -" ];

    virtualisation.oci-containers.containers.christina-keeper = {
      imageFile = keeperImage;
      image = "${keeperImage.imageName}:${keeperImage.imageTag}";
      autoStart = true;
      environment = {
        TZ = "America/New_York";
        # What the status page calls the machine; otherwise it would show the
        # container ID. KEEPER_BIND is baked into the image (0.0.0.0:8795).
        KEEPER_HOST = config.networking.hostName;
        # INSTAGRAM_TOKEN_FILE stays unset: /var/lib/christina-auth/token.json
        # is readable only by the christina-auth group, whose gid is not pinned,
        # so the container can't be given it reliably yet (docs/keeper.md).
      };
      volumes = [ "/var/lib/christina-keeper:/data" ];
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
