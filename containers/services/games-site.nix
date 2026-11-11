# Shared landing page for games.gignsky.com, run as a service on spacedock.
#
# Owns the single nginx vhost (`games-site`) that games.gignsky.com's front
# proxy forwards to on plain HTTP spacedock:1801 (see minecraft-create.nix for
# the one-time DNS/router/front-nginx setup -- unchanged by this file). This
# module only serves the hub page at `/`; each game contributes its own
# sub-page by adding `services.nginx.virtualHosts."games-site".locations` from
# its own file (minecraft-create.nix -> /minecraft/, space-engineers.nix ->
# /space-engineers/). Keeping the vhost itself in one place means the two
# pages share a domain/port instead of each needing its own front-nginx vhost.
{ pkgs, ... }:
let
  webPort = 1801;

  hub = pkgs.writeTextDir "index.html" ''
    <!doctype html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>Lord Gig's Game Servers</title>
      <style>
        body { font: 16px/1.5 system-ui, sans-serif; max-width: 40rem; margin: 2rem auto; padding: 0 1rem; }
        a.button {
          display: block; padding: .8em 1.2em; margin: .6em 0; background: #2b6cb0;
          color: #fff; border-radius: 6px; text-decoration: none; text-align: center;
        }
      </style>
    </head>
    <body>
      <h1>Lord Gig's Game Servers</h1>
      <a class="button" href="/minecraft/">Minecraft (Create)</a>
      <a class="button" href="/space-engineers/">Space Engineers</a>
    </body>
    </html>
  '';
in
{
  networking.firewall.allowedTCPPorts = [ webPort ];

  services.nginx = {
    enable = true;
    virtualHosts."games-site" = {
      listen = [
        {
          addr = "0.0.0.0";
          port = webPort;
        }
      ];
      root = hub;
    };
  };
}
