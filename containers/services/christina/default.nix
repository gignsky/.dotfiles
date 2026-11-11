# christinasceramics.com on spacedock: the admin keeper (main + beta) behind
# admin.christinasceramics.com / dev-admin.christinasceramics.com. The site
# itself is static on Cloudflare; the Instagram login (auth.christinasceramics.com)
# is a bare systemd unit in hosts/spacedock/christina-auth.nix, not a container.
_: {
  imports = [
    ./christina-keeper.nix # admin.christinasceramics.com keeper -- needs the keeper-env + admin-htpasswd sops secrets first
    ./christina-keeper-dev.nix # dev-admin.christinasceramics.com keeper -- autoStart = false; started/stopped by rolling-preview.yml
  ];
}
