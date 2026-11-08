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
# Exposed only on loopback; reach it through the host's existing reverse
# proxy (TLS/hostname are the operator's choice, not this module's).
{
  config,
  inputs,
  pkgs,
  ...
}:
let
  imageFile = inputs.ripae.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  sops.secrets.ripae-env = { };

  systemd.tmpfiles.rules = [ "d /var/lib/ripae 0750 root root -" ];

  virtualisation.oci-containers.containers.ripae = {
    inherit imageFile;
    image = "ripae:0.1.0";
    autoStart = true;
    environmentFiles = [ config.sops.secrets.ripae-env.path ];
    environment = {
      RIPAE_DB_PATH = "/data/ripae.db";
    };
    volumes = [ "/var/lib/ripae:/data" ];
    ports = [ "127.0.0.1:8080:8080" ];
    extraOptions = [
      "--health-cmd"
      "wget -qO- http://127.0.0.1:8080/healthz || exit 1"
    ];
  };
}
