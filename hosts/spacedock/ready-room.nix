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
  # Flip once both secrets sit in nix-secrets (`just sops`), owned by the
  # service user:
  #   ready-room:
  #     door-token: <any long random string>
  #     annex-key:  <private half of a read-only deploy key on gignsky/annex>
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
    };

    services.ready-room = {
      enable = true;
      configFile = ./ready-room.toml;
      doorTokenFile = config.sops.secrets."ready-room/door-token".path;
      sshKeyFile = config.sops.secrets."ready-room/annex-key".path;
      # Cloned into /var/lib/ready-room/clones/annex before the first start,
      # then pulled every five minutes by the core's watcher.
      clones.annex.url = "git@github.com:gignsky/annex.git";
      # For `summaries = "haiku"` the claude CLI must be on the service PATH:
      # extraPath = [ pkgs.claude-code ];
    };
  };
}
