# Ready Room — the ship's Computer: an MCP door onto the annex, served from
# spacedock. The module comes from the `ready-room` flake input
# (gignsky/ready-room, nix/module.nix); the config beside this file holds no
# secret. See ready-room's docs/spacedock.md for the whole walk.
{
  config,
  inputs,
  lib,
  ...
}:
let
  # Flip once the secrets sit in nix-secrets (`just sops`), owned by the
  # service user:
  #   ready-room:
  #     door-token:      <any long random string>
  #     annex-key:       <private half of a read-only deploy key on gignsky/annex>
  #     door-passphrase: <the phrase Lord Gig types on the door's sign-in page>
  # Until then the service is declared but not enabled, so the host still
  # evaluates and builds.
  haveSecrets = true;
in
{
  imports = [ inputs.ready-room.nixosModules.default ];

  config = lib.mkIf haveSecrets {
    sops.secrets = {
      "ready-room/door-token".owner = "ready-room";
      "ready-room/annex-key".owner = "ready-room";
      "ready-room/door-passphrase".owner = "ready-room";
    };

    services.ready-room = {
      enable = true;
      configFile = ./ready-room.toml;
      doorTokenFile = config.sops.secrets."ready-room/door-token".path;
      sshKeyFile = config.sops.secrets."ready-room/annex-key".path;
      # Opens the OAuth door (ready-room roll/1-1116-oauth): claude.ai adds
      # https://ready-room.giglab.dev/mcp as a custom connector and signs in
      # on the passphrase page the core serves. The bearer token still works.
      passphraseFile = config.sops.secrets."ready-room/door-passphrase".path;
      # Cloned into /var/lib/ready-room/clones/annex before the first start,
      # then pulled every five minutes by the core's watcher.
      clones.annex.url = "git@github.com:gignsky/annex.git";
      # For `summaries = "haiku"` the claude CLI must be on the service PATH:
      # extraPath = [ pkgs.claude-code ];
    };

    # The door listens on the LAN (ready-room.toml binds 0.0.0.0:7474). Do not
    # forward it on the router: away from the house it is reached through the
    # cloudflared tunnel below, which terminates TLS at Cloudflare.
    networking.firewall.allowedTCPPorts = [ 7474 ];

    # Public road: https://ready-room.giglab.dev/mcp, for merlin and the phone
    # (Pebble) away from home. Same tunnel as kottonmouth-keeper.nix and
    # christina-auth.nix (NixOS merges tunnels.<id>.ingress across files);
    # giglab.dev is in the same Cloudflare account as kottonmouthband.com.
    # The whole hostname is routed: /mcp (the door), /oauth/* and
    # /.well-known/* (the OAuth sign-in claude.ai needs), /health. The locks
    # are the door's own — bearer token or OAuth access token — since the
    # phone client cannot do a Cloudflare Access login; see ready-room.toml.
    #
    # Its proxied CNAME  ready-room -> <tunnel-id>.cfargotunnel.com  is
    # upserted on every switch by giglab-dns (hosts/spacedock/
    # cloudflare-dns.nix); the apex/DDNS records are left untouched.
    services.cloudflared.tunnels."1a878786-561d-427c-90cd-358f1b82aea4".ingress."ready-room.giglab.dev" =
      {
        service = "http://127.0.0.1:7474";
      };
  };
}
