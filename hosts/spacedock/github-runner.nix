# Self-hosted GitHub Actions runner for the kottonmouth repo's
# rolling-preview.yml workflow. Spacedock has no inbound ports open -- its
# only door in is the cloudflared tunnel in front of the admin gate(s) -- so
# there is no way for a GitHub-hosted job to reach it directly to deploy the
# beta wrangler environment or start/stop kottonmouth-keeper-dev. A
# self-hosted runner sidesteps that entirely: it long-polls GitHub outbound
# (same posture as the tunnel, nothing new exposed), and a workflow job
# targets it with `runs-on: [self-hosted, spacedock]`.
#
# One-time setup: generate a runner registration token (repo → Settings →
# Actions → Runners → New self-hosted runner, or the
# `POST /repos/{owner}/{repo}/actions/runners/registration-token` API) and
# store it at the `kottonmouth/github-runner-token` sops secret below. The
# token in the secret is only used once to register; nixos-module handles
# renewal/removal itself after that.
#
# The runner also needs a Cloudflare API token to run `wrangler deploy
# --env beta` -- stored at `kottonmouth/cloudflare-api-token` as a
# `CLOUDFLARE_API_TOKEN=...` line (systemd EnvironmentFile syntax, same
# convention as the oci-container `environmentFiles` secrets elsewhere in
# this repo) and loaded into the runner's service environment below.
{
  config,
  pkgs,
  ...
}:
{
  sops.secrets = {
    "kottonmouth/github-runner-token" = {
      restartUnits = [ "github-runner-kottonmouth.service" ];
    };
    "kottonmouth/cloudflare-api-token" = {
      restartUnits = [ "github-runner-kottonmouth.service" ];
    };
  };

  services.github-runners.kottonmouth = {
    enable = true;
    url = "https://github.com/gignsky/kottonmouth";
    tokenFile = config.sops.secrets."kottonmouth/github-runner-token".path;
    # Default labels already include self-hosted/Linux/X64; this is what
    # `runs-on: [self-hosted, spacedock]` in rolling-preview.yml matches on.
    extraLabels = [ "spacedock" ];
    extraPackages = with pkgs; [
      nodejs_22
      git
    ];
    serviceOverrides.EnvironmentFile = config.sops.secrets."kottonmouth/cloudflare-api-token".path;
  };

  # Privileged refresh+rebuild for deploy-beta, run as real root on demand via `systemctl start` (the sandboxed runner above can't gain root itself -- see the polkit rule below).
  systemd.services."kottonmouth-rolling-deploy" = {
    description = "Switch spacedock to the current tip of kottonmouth's rolling branch";
    restartIfChanged = false;
    unitConfig.X-StopOnRemoval = false;
    serviceConfig.Type = "oneshot";
    environment = config.nix.envVars // {
      inherit (config.environment.sessionVariables) NIX_PATH;
      HOME = "/root";
    } // config.networking.proxy.envVars;
    path = with pkgs; [
      coreutils
      gnutar
      xz.bin
      gzip
      gitMinimal
      config.nix.package.out
      config.programs.ssh.package
    ];
    script = ''
      dotfiles=/home/gig/.dotfiles

      # A branch that merely has github-runner.nix but not this unit (e.g. mid-graduation) would switch to a config missing the runner/polkit/unit entirely.
      if ! grep -q kottonmouth-rolling-deploy "$dotfiles/hosts/spacedock/github-runner.nix" 2>/dev/null; then
        echo "checked-out branch at $dotfiles lacks the deploy unit, refusing" >&2
        exit 1
      fi

      # Captured first so `-e` fails closed on a git error (e.g. dubious ownership running as root here) instead of $(...) going empty and passing silently; --no-optional-locks avoids fighting interactive roll-flow for .git/index.lock.
      status=$(git -c safe.directory="$dotfiles" -C "$dotfiles" --no-optional-locks status --porcelain)
      if [ -n "$status" ]; then
        echo "$dotfiles is dirty, refusing to switch against it" >&2
        exit 1
      fi

      # --refresh: nix caches a ref's resolved rev for tarball-ttl (1h) otherwise, which could deploy a stale `rolling` push and still report success.
      ${config.system.build.nixos-rebuild}/bin/nixos-rebuild switch \
        --flake "$dotfiles#spacedock" \
        --override-input kottonmouth-rolling "git+ssh://git@github.com/gignsky/kottonmouth.git?ref=rolling" \
        --no-write-lock-file \
        --refresh
    '';
  };

  # Scoped to exactly these two units for exactly this user, not blanket authorization -- same pattern as modules/nixos/binary-cache/watch.nix's pokeUsers rule.
  security.polkit = {
    enable = true;
    extraConfig = ''
      polkit.addRule(function (action, subject) {
        if (action.id !== "org.freedesktop.systemd1.manage-units" ||
            subject.user !== "github-runner-kottonmouth") {
          return;
        }
        var allowedVerbs = {
          "podman-kottonmouth-keeper-dev.service": [ "start", "stop" ],
          "kottonmouth-rolling-deploy.service": [ "start" ],
        }[action.lookup("unit")];
        if (allowedVerbs && allowedVerbs.indexOf(action.lookup("verb")) >= 0) {
          return polkit.Result.YES;
        }
      });
    '';
  };
}
