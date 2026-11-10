# Ready Room console — `rr` on every host, dialling the ship's Computer on
# spacedock (hosts/spacedock/ready-room.nix) over the public tunnel.
#
#   rr order "Computer, what did Radek's telegram say"
#   rr status
#
# The door token is the same sops secret the core reads on spacedock
# (`ready-room/door-token`), decrypted here with the gig/dev age key. The
# console config holds no secret, only where the door and the token file are.
#
# One URL everywhere: https://ready-room.giglab.dev/mcp is the cloudflared
# tunnel on spacedock, so it works at home and away (it hairpins out through
# Cloudflare at home). If the tunnel is down, `RR_URL=http://192.168.51.2:7474/mcp`
# reaches the door directly on the LAN; `RR_TOKEN` overrides the token file.
{
  config,
  inputs,
  system,
  ...
}:
{
  home.packages = [ inputs.ready-room.packages.${system}.default ];

  sops.secrets."ready-room/door-token" = { };

  xdg.configFile."ready-room/ready-room.toml".text = ''
    [console]
    url = "https://ready-room.giglab.dev/mcp"
    token_file = "${config.sops.secrets."ready-room/door-token".path}"
  '';
}
