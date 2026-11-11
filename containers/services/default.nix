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
    ./ripae.nix # Org commodity-run ledger — needs the `ripae-env` sops key first, see file header
    ./games-site.nix # games.gignsky.com hub page on :1801 — minecraft-create.nix and space-engineers.nix add their own sub-pages to it
    ./minecraft-create.nix # Create (NeoForge) Minecraft server + its games.gignsky.com/minecraft/ page, see file header
    ./kottonmouth # kottonmouthband.com keeper (main + beta) and tunnel DNS, see kottonmouth/default.nix
    ./christina # admin.christinasceramics.com keeper, see christina/default.nix
    ./space-engineers.nix # Space Engineers dedicated server under Wine — UDP 27016/8766, password-gated, see file header
  ];
}
