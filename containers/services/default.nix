# Run-as-a-service OCI containers, carried from dot-spacedock.
#
# The container runtime is provided by the gigpkgs container engine
# (`gigpkgs.containers.enable = true` on the host). Uncomment a payload to run
# it.
_: {
  imports = [
    ./pihole.nix # Pi-hole DNS slave, synced from memory-alpha — needs the `pihole/*` sops keys, see file header
    ./tdarr-node.nix # Tdarr node — needs CIFS mounts + samba creds first
    ./floatplane-wan-show.nix # Floatplane downloader (WAN Show + Techquickie) → Sonarr, see file header
    ./avec-moi-app.nix
    ./scribbydascribe.nix # Discord voice transcriber — needs the `scribbydascribe-env` sops key first
    ./kottonmouth # kottonmouthband.com keeper (main + beta) and tunnel DNS, see kottonmouth/default.nix
    ./christina # admin.christinasceramics.com keeper, see christina/default.nix
  ];
}
