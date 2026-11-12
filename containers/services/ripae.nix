# Ripae — org commodity-run ledger (axum + sqlx, SQLite), run as a service on
# spacedock. See gignsky/ripae, RIPAE-ALPHA.md §6 for the target shape this
# follows.
#
# The image comes from the `ripae` flake input (a `dockerTools.buildLayeredImage`
# tarball, `nix build .#container`), the same way avec-moi-app.nix and
# scribbydascribe.nix do it.
#
# Before the first switch:
#   1. Add to nix-secrets/secrets.yaml (`just sops`) a key `ripae-env` whose
#      value is an env file:
#        RIPAE_SESSION_SECRET=<64 random bytes, base64>
#        RIPAE_SEED_USERS=lordgig:Lord Gig:<pw>,firstofficer:First Officer:<pw>
#      validateSopsFiles is on, so the build fails until the key exists.
#      Seeding only runs while `users` is empty, so RIPAE_SEED_USERS can be
#      dropped from the secret after the first boot.
#   2. This flake input is already wired (flake.nix, `ripae` → `github:gignsky/ripae/master`).
#
# Exposed on the LAN at :8089 (plain HTTP, same as avec-moi-app.nix on :8081).
{
  config,
  inputs,
  pkgs,
  ...
}:
let
  # `default` is the bare binary; `container` is the buildLayeredImage tarball.
  imageFile = inputs.ripae.packages.${pkgs.stdenv.hostPlatform.system}.container;

  # Runs as root via the sudo rule below; `scripts/dev.sh live` in the ripae
  # repo calls it over ssh to pull a copy of the live database. The script
  # comes from the ripae input, so `nix flake update ripae` picks up changes.
  ripae-snapshot = pkgs.writeShellApplication {
    name = "ripae-snapshot";
    runtimeInputs = [
      pkgs.sqlite
      pkgs.coreutils
      pkgs.getent
    ];
    text = builtins.readFile "${inputs.ripae}/scripts/spacedock-snapshot.sh";
  };
in
{
  sops.secrets.ripae-env = { };

  environment.systemPackages = [ ripae-snapshot ];

  # gig may run exactly this one command as root, without a password.
  security.sudo.extraRules = [
    {
      users = [ "gig" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/ripae-snapshot";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  systemd.tmpfiles.rules = [ "d /var/lib/ripae 0750 root root -" ];

  virtualisation.oci-containers.containers.ripae = {
    inherit imageFile;
    # Track the tarball's own name:tag, so a version bump upstream can't leave
    # this pointing at a stale image still sitting in podman's store.
    image = "${imageFile.imageName}:${imageFile.imageTag}";
    autoStart = true;
    environmentFiles = [ config.sops.secrets.ripae-env.path ];
    environment = {
      RIPAE_DB_PATH = "/data/ripae.db";
      # Served over plain HTTP on the LAN; a `Secure` cookie would be dropped.
      RIPAE_COOKIE_SECURE = "0";
    };
    volumes = [ "/var/lib/ripae:/data" ];
    # Host 8089 -> ripae's default RIPAE_BIND of 0.0.0.0:8080 in the container.
    # No --health-cmd: the Nix image has no shell or wget to run one.
    ports = [
      "8089:8080/tcp"
    ];
  };
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 8089 ];
  };
}
