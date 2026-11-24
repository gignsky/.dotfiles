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
  pkgs,
  system,
  ...
}:
let
  tokenFile = config.sops.secrets."ready-room/door-token".path;

  # Claude Code expands ${VAR} in an MCP server's headers, but only from its
  # own environment, and the token lives in a sops file. So wrap `claude` to
  # export it at launch: the secret never lands in a config file, the Nix
  # store, or ~/.claude.json. A missing file just leaves it empty (the door
  # answers 401; every other MCP server is unaffected).
  claudeWithDoorToken = pkgs.symlinkJoin {
    name = "claude-code-ready-room";
    inherit (pkgs.unstable.claude-code) pname version meta;
    paths = [ pkgs.unstable.claude-code ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/claude \
        --run 'export READY_ROOM_TOKEN="$(cat ${tokenFile} 2>/dev/null)"'
    '';
  };
in
{
  home.packages = [ inputs.ready-room.packages.${system}.default ];

  # The ship's Computer as a Claude Code MCP server on every host (replaces
  # the bare `unstable.claude-code` in home.nix). Streamable HTTP, so no
  # local clone is needed; `rr mcp` (stdio) is for a console that holds one.
  programs.claude-code = {
    enable = true;
    package = claudeWithDoorToken;
    mcpServers.ready-room = {
      type = "http";
      url = "https://ready-room.giglab.dev/mcp";
      headers.Authorization = "Bearer \${READY_ROOM_TOKEN}";
    };
  };

  sops.secrets."ready-room/door-token" = { };

  xdg.configFile."ready-room/ready-room.toml".text = ''
    [console]
    url = "https://ready-room.giglab.dev/mcp"
    token_file = "${config.sops.secrets."ready-room/door-token".path}"
  '';
}
