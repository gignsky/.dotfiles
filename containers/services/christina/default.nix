# christinasceramics.com on spacedock: the admin keeper behind
# admin.christinasceramics.com. The site itself is static on Cloudflare; the
# Instagram login (auth.christinasceramics.com) is a bare systemd unit in
# hosts/spacedock/christina-auth.nix, not a container, so it lives there.
_: {
  imports = [
    ./christina-keeper.nix # admin.christinasceramics.com keeper -- needs the admin-htpasswd sops secret first
  ];
}
