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
# store it at the `github-runner/kottonmouth-token` sops secret below. The
# token in the secret is only used once to register; nixos-module handles
# renewal/removal itself after that.
{
  config,
  pkgs,
  ...
}:
{
  sops.secrets."github-runner/kottonmouth-token" = {
    restartUnits = [ "github-runner-kottonmouth.service" ];
  };

  services.github-runners.kottonmouth = {
    enable = true;
    url = "https://github.com/gignsky/kottonmouth";
    tokenFile = config.sops.secrets."github-runner/kottonmouth-token".path;
    # Default labels already include self-hosted/Linux/X64; this is what
    # `runs-on: [self-hosted, spacedock]` in rolling-preview.yml matches on.
    extraLabels = [ "spacedock" ];
    extraPackages = with pkgs; [
      nodejs_22
      nixos-rebuild
      git
    ];
  };

  # Scoped to exactly what rolling-preview.yml runs as root -- not blanket
  # sudo for the runner's service user. Interpolating `${pkgs.foo}/bin/...`
  # (the same `pkgs.nixos-rebuild` as extraPackages above) rather than a
  # `/run/current-system/sw/bin/...` path, so sudoers' exact-argument match
  # lines up with whatever nixos-rebuild the runner actually resolves on its
  # PATH -- a wrapper/PATH path wouldn't match a hardcoded store path.
  security.sudo.extraRules = [
    {
      users = [ "github-runner-kottonmouth" ];
      commands = [
        {
          command = "${pkgs.nixos-rebuild}/bin/nixos-rebuild switch --flake /home/gig/.dotfiles#spacedock";
          options = [ "NOPASSWD" ];
        }
        {
          command = "${pkgs.systemd}/bin/systemctl start podman-kottonmouth-keeper-dev.service";
          options = [ "NOPASSWD" ];
        }
        {
          command = "${pkgs.systemd}/bin/systemctl stop podman-kottonmouth-keeper-dev.service";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
