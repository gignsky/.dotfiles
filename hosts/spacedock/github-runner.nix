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
    "gigpkgs/github-runner-token" = {
      restartUnits = [ "github-runner-gigpkgs.service" ];
    };
    "kottonmouth/github-runner-token" = {
      restartUnits = [ "github-runner-kottonmouth.service" ];
    };
    "kottonmouth/cloudflare-api-token" = {
      restartUnits = [ "github-runner-kottonmouth.service" ];
    };
    # Read-only GitHub deploy key for kottonmouth-rolling-deploy.service below
    # -- root has no SSH credentials of its own, and gig's personal key only
    # exists in a per-session tmpfs (home-manager sops-nix), so it isn't
    # available when gig is logged out.
    "kottonmouth/rolling-deploy-key" = {
      owner = "root";
      mode = "0400";
    };
  };
  services.github-runners = {
    gigpkgs = {
      enable = true;
      url = "https://github.com/gignsky/gigpkgs";
      tokenFile = config.sops.secrets."gigpkgs/github-runner-token".path;
      extraLabels = [ "spacedock" ];
      extraPackages = with pkgs; [
        gnused
        gnugrep
        cargo
        rustc
        gcc
      ];
    };
    kottonmouth = {
      enable = true;
      url = "https://github.com/gignsky/kottonmouth";
      tokenFile = config.sops.secrets."kottonmouth/github-runner-token".path;
      # Default labels already include self-hosted/Linux/X64; this is what
      # `runs-on: [self-hosted, spacedock]` in rolling-preview.yml matches on.
      extraLabels = [ "spacedock" ];
      extraPackages = with pkgs; [
        nodejs_22
        nixos-rebuild
        git
        cargo
        rustc
        gcc
      ];
      serviceOverrides.EnvironmentFile = config.sops.secrets."kottonmouth/cloudflare-api-token".path;
    };
  };

  # Privileged refresh+rebuild for deploy-beta, run as real root on demand via `systemctl start` (the sandboxed runner above can't gain root itself -- see the polkit rule below).
  systemd.services."kottonmouth-rolling-deploy" = {
    description = "Switch spacedock to the current tip of kottonmouth's rolling branch";
    restartIfChanged = false;
    unitConfig.X-StopOnRemoval = false;
    serviceConfig.Type = "oneshot";
    environment =
      config.nix.envVars
      // {
        inherit (config.environment.sessionVariables) NIX_PATH;
        HOME = "/root";
        GIT_SSH_COMMAND = "${config.programs.ssh.package}/bin/ssh -i ${
          config.sops.secrets."kottonmouth/rolling-deploy-key".path
        } -o IdentitiesOnly=yes";
      }
      // config.networking.proxy.envVars;
    path = with pkgs; [
      coreutils
      gnutar
      xz.bin
      gzip
      gitMinimal
      config.nix.package.out
      config.programs.ssh.package
    ];
    # Private clone of the dotfiles repo owned by this unit alone (/var/lib/kottonmouth-deploy), so deploys never read gig's live checkout -- roll-flow moves that between branches mid-graduation, which used to trip the guard below (2026-10-20 23:45).
    serviceConfig.StateDirectory = "kottonmouth-deploy";
    script = ''
      clone=/var/lib/kottonmouth-deploy/dotfiles
      # Branch the deploy follows; the public repo needs no credentials, so the deploy key above stays scoped to the kottonmouth repo.
      ref=develop

      if [ ! -d "$clone/.git" ]; then
        git init --quiet "$clone"
        git -C "$clone" remote add origin https://github.com/gignsky/.dotfiles.git
      fi

      # Shallow fetch + hard reset: the clone is disposable and holds no local state, so there is nothing to be dirty and nothing to race.
      git -C "$clone" fetch --quiet --depth 1 origin "$ref"
      git -C "$clone" reset --quiet --hard FETCH_HEAD
      git -C "$clone" clean --quiet -fdx

      # A tip that merely has github-runner.nix but not this unit would switch to a config missing the runner/polkit/unit entirely.
      if ! grep -q kottonmouth-rolling-deploy "$clone/hosts/spacedock/github-runner.nix" 2>/dev/null; then
        echo "origin/$ref lacks the deploy unit, refusing" >&2
        exit 1
      fi

      # --refresh: nix caches a ref's resolved rev for tarball-ttl (1h) otherwise, which could deploy a stale `rolling` push and still report success.
      ${config.system.build.nixos-rebuild}/bin/nixos-rebuild switch \
        --flake "$clone#spacedock" \
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
