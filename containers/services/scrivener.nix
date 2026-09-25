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
#          url = "github:gignsky/scribbydascribe/master";
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
      # Unset, ctranslate2 takes its default of 4 threads and leaves the other
      # 8 of spacedock's cores idle, which is how a five-speaker call builds a
      # backlog it never catches up on. Two cores are held back for the bot,
      # the ffmpeg track build at the end, and everything else on the host.
      WHISPER_THREADS = "10";
    };
    volumes = [ "/var/lib/scrivener:/data" ];
    # On stop the bot finishes any recording in progress (drains the
    # transcription queue, writes the files, posts the transcript) before
    # exiting, so give it time rather than the default 10 s.
    extraOptions = [ "--stop-timeout=600" ];
  };

  systemd.services.podman-scrivener = {
    serviceConfig.TimeoutStopSec = lib.mkForce 660;

    # A rebuild must never take a recording down with it. Stopping the
    # container is graceful but final: the bot finishes the session, posts the
    # transcript and exits, which in the middle of a game night is exactly the
    # interruption we are trying to avoid. So a switch installs the new unit
    # and leaves the running container alone; the changeover happens on an
    # explicit `systemctl restart podman-scrivener` at a break.
    #
    # switch-to-configuration reads X-RestartIfChanged from the *new*
    # generation's unit file, so this already governs the switch that
    # introduces it. The cost is that it is now on us to remember: until that
    # restart, the container keeps running whatever image it started with, no
    # matter how many rebuilds go past.
    restartIfChanged = false;
  };
}
