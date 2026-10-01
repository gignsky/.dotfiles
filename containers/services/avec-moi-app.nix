# avec-moi.app — Ask an Appraiser question box (Python server on :8080),
# packaged as an OCI image by the `avec-moi` flake input.
#
# The image comes from `avec-moi.packages.<system>.default` (a
# `dockerTools.buildLayeredImage` tarball tagged `avecmoi:latest`). NOTE:
# `packages.<system>.app` is NOT the image — it is just the server wrapper
# that the image runs. We reference the input by `pkgs.system` so the module
# does not need `system` threaded through `specialArgs`.
#
# /admin (review submitted questions) uses root's password: the `root-password`
# sops secret (a crypt hash, declared in hosts/common/core/sops.nix) is mounted
# read-only and the site checks logins against it. Any username works.
#
# Submitted questions land in /var/lib/avec-moi/questions.jsonl.
{
  config,
  inputs,
  pkgs,
  ...
}:
let
  imageFile = inputs.avec-moi.packages.${pkgs.system}.default;
in
{
  systemd.tmpfiles.rules = [ "d /var/lib/avec-moi 0750 root root -" ];

  virtualisation.oci-containers.containers.avec-moi-app = {
    inherit imageFile;
    image = "avecmoi:latest";
    autoStart = true;
    environment = {
      TZ = "America/New_York";
      ADMIN_PASSWORD_HASH_FILE = "/run/secrets/admin-password-hash";
    };
    volumes = [
      "/var/lib/avec-moi:/data"
      "${config.sops.secrets.root-password.path}:/run/secrets/admin-password-hash:ro"
    ];
    ports = [
      "8081:8080/tcp"
    ];
  };
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 8081 ];
  };
}
