# giglab.dev — interim image only: static-web-server serving the Astro
# build (`packages.site`), packaged by the `giglab-dev` flake input
# (`packages.<system>.image`). There is no Rust keeper, no /api, no SQLite
# poller yet — no server/ exists in that repo. There is also no
# nix/container-config.nix / containers.<system>.giglab yet (the
# dot-spacedock lib/container-config pattern, for inputMan discovery), so
# this references the image directly, the same way avec-moi-app.nix and
# kottonmouth-keeper.nix do.
#
# Direct port, no reverse proxy, no TLS: this is NOT the public
# https://giglab.dev front door (giglab.dev's own AGENTS.md rules that out —
# host nginx + ACME is the only sanctioned way in, and neither exists on
# spacedock yet either). Reachable for now at http://<spacedock-lan-ip>:8800/.
# No state, no secrets: the site is a static build with nothing to persist.
{
  inputs,
  pkgs,
  ...
}:
{
  virtualisation.oci-containers.containers.giglab-dev = {
    imageFile = inputs.giglab-dev.packages.${pkgs.stdenv.hostPlatform.system}.image;
    image = "giglab-dev:latest";
    autoStart = true;
    ports = [
      "8800:8800/tcp"
    ];
  };
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 8800 ];
  };
}
