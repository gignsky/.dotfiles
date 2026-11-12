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
#
# Also serves `/status.js`, shared JS each game's page (and this hub) uses to
# poll that game's `status.json` (written by its own status-check timer, see
# minecraft-create.nix / space-engineers.nix) and show Online/Offline.
{ pkgs, ... }:
let
  webPort = 1801;

  statusJs = pkgs.writeText "status.js" ''
    async function loadStatus(url, elId) {
      var el = document.getElementById(elId);
      if (!el) return;
      try {
        var res = await fetch(url, { cache: "no-store" });
        if (!res.ok) throw new Error("bad response");
        var data = await res.json();
        if (data.online) {
          el.textContent = (typeof data.players === "number" && typeof data.max_players === "number")
            ? "Online — " + data.players + "/" + data.max_players + " players"
            : "Online";
          el.className = "status online";
        } else {
          el.textContent = "Offline";
          el.className = "status offline";
        }
      } catch (e) {
        el.textContent = "Status unavailable";
        el.className = "status unknown";
      }
    }
    function pollStatus(url, elId) {
      loadStatus(url, elId);
      setInterval(function () { loadStatus(url, elId); }, 30000);
    }
  '';

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
        .status-line { margin: -.4em 0 .8em; font-size: .9em; text-align: center; color: #666; }
        .status.online { color: #2b8a3e; font-weight: 600; }
        .status.offline { color: #999; }
        .status.unknown { color: #d9822b; }
      </style>
    </head>
    <body>
      <h1>Lord Gig's Game Servers</h1>
      <a class="button" href="/minecraft/">Minecraft (Create)</a>
      <p class="status-line">Status: <span id="mc-status" class="status">checking&hellip;</span></p>
      <a class="button" href="/space-engineers/">Space Engineers</a>
      <p class="status-line">Status: <span id="se-status" class="status">checking&hellip;</span></p>
      <script src="/status.js"></script>
      <script>
        pollStatus("/minecraft/status.json", "mc-status");
        pollStatus("/space-engineers/status.json", "se-status");
      </script>
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
      locations."= /status.js".alias = "${statusJs}";
    };
  };
}
