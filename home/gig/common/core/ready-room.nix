# Ready Room console — `rr` on every host, dialling the ship's Computer on
# spacedock (hosts/spacedock/ready-room.nix) over the LAN.
#
#   rr order "Computer, what did Radek's telegram say"
#   rr status
#
# The door token is the same sops secret the core reads on spacedock
# (`ready-room/door-token`), decrypted here with the gig/dev age key. The
# console config holds no secret, only where the door and the token file are.
#
# LAN only: away from the house the door is out of reach until a public road
# exists. `RR_URL` / `RR_TOKEN` override the config for a tunnel.
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
    url = "http://192.168.51.2:7474/mcp"
    token_file = "${config.sops.secrets."ready-room/door-token".path}"
  '';
}
