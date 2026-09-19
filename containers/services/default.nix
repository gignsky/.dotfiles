# Run-as-a-service OCI containers, carried from dot-spacedock.
#
# The container runtime is provided by the gigpkgs container engine
# (`gigpkgs.containers.enable = true` on the host). Comment a payload out to
# stop running it.
_: {
  imports = [
    ./pihole.nix # Pi-hole DNS replica + nebula-sync from the master on memory-alpha
    ./tdarr-node.nix # Tdarr node — needs CIFS mounts + samba creds first
    ./avec-moi-app.nix
  ];
}
