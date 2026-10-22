# Run-as-a-service OCI containers, carried from dot-spacedock.
#
# The container runtime is provided by the gigpkgs container engine
# (`gigpkgs.containers.enable = true` on the host). Uncomment a payload to run
# it. pihole is enabled so spacedock has a working container out of the box.
_: {
  imports = [
    ./kottonmouth-keeper.nix # kottonmouthband.com keeper — needs its sops secrets + tunnel first
    ./kottonmouth-keeper-dev.nix # beta.kottonmouthband.com keeper — autoStart = false; started/stopped by rolling-preview.yml
    ./kottonmouth-dns.nix # DNS records for the tunnel hostnames above — needs a DNS-edit Cloudflare token
  ];
}
