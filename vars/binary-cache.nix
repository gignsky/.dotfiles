# Fleet binary cache (Harmonia on spacedock). See docs/guides/BINARY-CACHE.md.
#
# `publicKey` stays null until the signing key has been generated and stored in
# nix-secrets; while null, clients simply don't use the cache.
{
  serverHost = "spacedock"; # networking.hostName of the server
  sshTarget = "spacedock"; # ~/.ssh/config host used for pushes
  url = "http://192.168.51.2:5000";
  publicKey = "spacedock-cache-1:/M65sHAOdhlDXRoEx5QaxMrqy0Fe5MtrPa5KykiEKEs=";
}
