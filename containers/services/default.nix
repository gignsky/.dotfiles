# Run-as-a-service OCI containers, carried from dot-spacedock.
#
# The container runtime is provided by the gigpkgs container engine
# (`gigpkgs.containers.enable = true` on the host). Uncomment a payload to run
# it. pihole is enabled so spacedock has a working container out of the box.
_: {
  imports = [
    ./pihole.nix # Pi-hole DNS — runs as a service via the container engine
    # ./tdarr-node.nix  # Tdarr node — needs CIFS mounts + samba creds first
  ];
}
