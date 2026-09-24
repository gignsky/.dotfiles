# scrivener: Discord voice-call recorder and per-speaker transcriber, run as
# a service on spacedock. Drop this file into `containers/services/` in
# .dotfiles and import it from `containers/services/default.nix`.
#
# The image comes from the `scrivener` flake input (a
# `dockerTools.buildLayeredImage` tarball tagged `scrivener:latest`), the same
# way avec-moi-app.nix does it.
#
# Before the first switch:
#   1. Add to nix-secrets/secrets.yaml (`just sops`) a key `scrivener-env`
#      whose value is an env file:
#        DISCORD_TOKEN=<bot token>
#        DISCORD_GUILD_ID=<server id>   # optional: instant command registration
#      validateSopsFiles is on, so the build fails until the key exists.
#   2. Add the flake input in flake.nix:
#        scrivener = {
#          url = "github:gignsky/scribbydascribe";
#          inputs.nixpkgs.follows = "nixpkgs";
#        };
#
# Session folders land in /var/lib/scrivener/sessions; the Whisper model is
# downloaded once into /var/lib/scrivener/models on first start.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  imageFile = inputs.scrivener.packages.${pkgs.system}.default;
in
{
  sops.secrets.scrivener-env = { };

  systemd.tmpfiles.rules = [ "d /var/lib/scrivener 0750 root root -" ];

  virtualisation.oci-containers.containers.scrivener = {
    inherit imageFile;
    image = "scrivener:latest";
    autoStart = true;
    environmentFiles = [ config.sops.secrets.scrivener-env.path ];
    environment = {
      TZ = "America/New_York";
      # spacedock's Polaris GPU has no CUDA, so Whisper runs on the CPU.
      # "small" keeps up with a lively call on a few cores; "medium" is more
      # accurate but roughly 3x slower. Sessions finish either way: clips that
      # arrive faster than they transcribe just queue.
      WHISPER_MODEL = "small";
      WHISPER_DEVICE = "cpu";
      WHISPER_COMPUTE_TYPE = "int8";
      WHISPER_LANGUAGE = "en";
    };
    volumes = [ "/var/lib/scrivener:/data" ];
    # On stop the bot finishes any recording in progress (drains the
    # transcription queue, writes the files, posts the transcript) before
    # exiting, so give it time rather than the default 10 s.
    extraOptions = [ "--stop-timeout=600" ];
  };

  systemd.services.podman-scrivener.serviceConfig.TimeoutStopSec = lib.mkForce 660;
}
