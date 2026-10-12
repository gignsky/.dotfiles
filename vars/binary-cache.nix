# Fleet binary cache (Harmonia on spacedock). See docs/guides/BINARY-CACHE.md.
#
# `publicKey` stays null until the signing key has been generated and stored in
# nix-secrets; while null, clients simply don't use the cache.
{
  serverHost = "spacedock"; # networking.hostName of the server
  sshTarget = "spacedock"; # ~/.ssh/config host used for pushes
  url = "http://192.168.51.2:5000";
  publicKey = "spacedock-cache-1:/M65sHAOdhlDXRoEx5QaxMrqy0Fe5MtrPa5KykiEKEs=";

  # Push-on-build (post-build hook). Runs as root, so it can't use ~/.ssh/config:
  # it connects to `pushHost` directly with its own key and a pinned host key.
  pushHost = "192.168.51.2";
  hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDmBvxBTdFdO0IKT30vqec/JkfjAjlv7trlh+tPuK0W2";
  # Public half of `binary-cache/push-key` in nix-secrets. While null, no host
  # pushes on build and the server creates no push account.
  pushPublicKey = null;
}
