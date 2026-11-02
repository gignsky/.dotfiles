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
  inputs,
  config,
  pkgs,
  ...
}:
let
  # Privileged image refresh for deploy-beta, run as real root on demand via `systemctl start` (the sandboxed runner can't gain root itself -- see the polkit rule below).
  # Builds only the dev keeper's image off the repo's `rolling` tip and loads it into podman -- no nixos-rebuild, so a beta deploy never resets spacedock to some branch's config (reverting roll work) or restarts the runner mid-job.
  mkRollingDeploy =
    {
      repo,
      keyFile,
      container,
      state,
    }:
    {
      description = "Load the dev keeper image from the current tip of ${repo}'s rolling branch";
      restartIfChanged = false;
      unitConfig.X-StopOnRemoval = false;
      serviceConfig = {
        Type = "oneshot";
        # Holds the out-link that GC-roots the current image.
        StateDirectory = state;
      };
      environment =
        config.nix.envVars
        // {
          HOME = "/root";
          GIT_SSH_COMMAND = "${config.programs.ssh.package}/bin/ssh -i ${keyFile} -o IdentitiesOnly=yes";
        }
        // config.networking.proxy.envVars;
      path = with pkgs; [
        coreutils
        gitMinimal
        gnutar
        gzip
        jq
        skopeo
        config.nix.package.out
        config.programs.ssh.package
        config.virtualisation.podman.package
        config.systemd.package
      ];
      script = ''
        state=/var/lib/${state}
        # Leftover dotfiles clone from when this unit ran nixos-rebuild.
        rm -rf "$state/dotfiles"

        # --refresh: nix caches a ref's resolved rev for tarball-ttl (1h) otherwise, which could load a stale `rolling` push and still report success.
        # nixpkgs pinned to the system's so the image matches what the old flake-input build produced (and hits the binary cache).
        nix build --refresh \
          'git+ssh://git@github.com/gignsky/${repo}.git?ref=rolling#keeper-image' \
          --override-input nixpkgs 'path:${inputs.nixpkgs}' \
          --out-link "$state/keeper-image"

        # Tag the dev image with rolling's keeper version, read from the tag the archive bakes (`<repo>-keeper:<version>`).
        archive=$(readlink -f "$state/keeper-image")
        KEEPER_DEV_TAG=$(tar -xzOf "$archive" manifest.json | jq -er '.[0].RepoTags[0] | split(":") | last')
        # The dev container unit reads this as its EnvironmentFile to pick the same tag.
        echo "KEEPER_DEV_TAG=$KEEPER_DEV_TAG" > "$state/dev-tag.env.tmp"
        mv "$state/dev-tag.env.tmp" "$state/dev-tag.env"

        # Copied under its own name: the archive bakes `<repo>-keeper:<version>`, which is the main keeper's ref whenever rolling and main share a version.
        # The image string expands `$KEEPER_DEV_TAG` set above.
        skopeo copy --quiet \
          "docker-archive:$archive" \
          containers-storage:${config.virtualisation.oci-containers.containers.${container}.image}

        # A running container keeps its old image, and the workflow's `systemctl start` is a no-op on it.
        systemctl try-restart podman-${container}.service
        podman image prune -f
      '';
    };
in
{
  sops.secrets = {
    "gigpkgs/github-runner-token" = {
      restartUnits = [ "github-runner-gigpkgs.service" ];
    };
    "christina-website/github-runner-token" = {
      restartUnits = [ "github-runner-christina-website.service" ];
    };
    "christina-website/beta-env" = {
      restartUnits = [ "github-runner-christina-website.service" ];
    };
    # rolling-preview.yml's beta Worker secrets for the christina runner, as
    # EnvironmentFile lines: BETA_KEEPER_TOKEN, BETA_ADMIN_PROXY_SECRET, optional
    # BETA_TURNSTILE_SECRET. Values must match christina-website/keeper-dev-env
    # (KEEPER_TOKEN, PROXY_SECRET).
    "christina-website/beta-worker-secrets" = {
      restartUnits = [ "github-runner-christina-website.service" ];
    };
    # Read-only deploy key on the christina-website repo for
    # christina-rolling-deploy.service (deploy keys are per repo).
    "christina-website/rolling-deploy-key" = {
      owner = "root";
      mode = "0400";
    };
    "kottonmouth/github-runner-token" = {
      restartUnits = [ "github-runner-kottonmouth.service" ];
    };
    "kottonmouth/cloudflare-api-token" = {
      restartUnits = [ "github-runner-kottonmouth.service" ];
    };
    # Beta Worker secrets for rolling-preview.yml's "Restore beta Worker
    # secrets" step, as EnvironmentFile lines: BETA_ADMIN_PROXY_SECRET,
    # BETA_KEEPER_TOKEN, BETA_RSVP_SALT, optional BETA_TURNSTILE_SECRET. Values
    # must match kottonmouth-keeper-dev-env (PROXY_SECRET, KEEPER_TOKEN).
    "kottonmouth/beta-worker-secrets" = {
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
    christina-website = {
      enable = true;
      url = "https://github.com/gignsky/christina-website";
      tokenFile = config.sops.secrets."christina-website/github-runner-token".path;
      # Default labels already include self-hosted/Linux/X64; this is what
      # `runs-on: [self-hosted, spacedock]` in rolling-preview.yml matches on.
      extraLabels = [ "spacedock" ];
      extraPackages = with pkgs; [
        nodejs_22
        git
        # actions/checkout with `lfs: true` shells out to git-lfs (images are LFS-tracked).
        git-lfs
        # site-hash.sh builds the keeper and check.yml runs its tests.
        cargo
        rustc
        gcc
        gnused
        gnugrep
      ];
      # CLOUDFLARE_API_TOKEN for `wrangler deploy --env beta`, one KEY=value per line,
      # same convention as the kottonmouth runner above. The Instagram token is not
      # here: christina-auth.service keeps it in /var/lib/christina-auth/token.json
      # (christina-auth.nix) and the workflow reads it at build time.
      # BETA_* (beta-worker-secrets) are the beta Worker secrets rolling-preview.yml restores.
      serviceOverrides.EnvironmentFile = [
        config.sops.secrets."christina-website/beta-env".path
        config.sops.secrets."christina-website/beta-worker-secrets".path
      ];
      serviceOverrides.SupplementaryGroups = [ "christina-auth" ];
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
      serviceOverrides.EnvironmentFile = [
        config.sops.secrets."kottonmouth/cloudflare-api-token".path
        config.sops.secrets."kottonmouth/beta-worker-secrets".path
      ];
    };
  };

  systemd.services."kottonmouth-rolling-deploy" = mkRollingDeploy {
    repo = "kottonmouth";
    keyFile = config.sops.secrets."kottonmouth/rolling-deploy-key".path;
    container = "kottonmouth-keeper-dev";
    state = "kottonmouth-deploy";
  };

  systemd.services."christina-rolling-deploy" = mkRollingDeploy {
    repo = "christina-website";
    keyFile = config.sops.secrets."christina-website/rolling-deploy-key".path;
    container = "christina-keeper-dev";
    state = "christina-deploy";
  };

  # Scoped to exactly these units for exactly these users, not blanket authorization -- same pattern as modules/nixos/binary-cache/watch.nix's pokeUsers rule.
  security.polkit = {
    enable = true;
    extraConfig = ''
      polkit.addRule(function (action, subject) {
        if (action.id !== "org.freedesktop.systemd1.manage-units") {
          return;
        }
        var allowedUnits = {
          "github-runner-kottonmouth": {
            "podman-kottonmouth-keeper-dev.service": [ "start", "stop" ],
            "kottonmouth-rolling-deploy.service": [ "start" ],
          },
          "github-runner-christina-website": {
            "podman-christina-keeper-dev.service": [ "start", "stop" ],
            "christina-rolling-deploy.service": [ "start" ],
          },
        }[subject.user];
        var allowedVerbs = allowedUnits && allowedUnits[action.lookup("unit")];
        if (allowedVerbs && allowedVerbs.indexOf(action.lookup("verb")) >= 0) {
          return polkit.Result.YES;
        }
      });
    '';
  };
}
