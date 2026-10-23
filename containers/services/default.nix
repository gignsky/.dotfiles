# Run-as-a-service OCI containers, carried from dot-spacedock.
#
# The container runtime is provided by the gigpkgs container engine
# (`gigpkgs.containers.enable = true` on the host). Uncomment a payload to run
# it. pihole is enabled so spacedock has a working container out of the box.
_: {
  imports = [
    # ./pihole.nix # Pi-hole DNS — runs as a service via the container engine
    ./tdarr-node.nix # Tdarr node — needs CIFS mounts + samba creds first
    ./floatplane-wan-show.nix # Floatplane downloader (WAN Show + Techquickie) → Sonarr, see file header
    ./avec-moi-app.nix
    ./giglab-dev.nix # giglab.dev — interim static image, no TLS/front door yet
    ./scribbydascribe.nix # Discord voice transcriber — needs the `scribbydascribe-env` sops key first
    ./kottonmouth # kottonmouthband.com keeper (main + beta) and tunnel DNS, see kottonmouth/default.nix
  ];
}
