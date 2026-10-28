# Minecraft Java server with the Create mod (NeoForge 1.21.1), run as a
# service on spacedock via the itzg/minecraft-server image. The image installs
# NeoForge and downloads the mods listed in `mods` below from Modrinth on
# start; the world, configs and mods all live in /var/lib/minecraft-create.
#
# Public, whitelist off (for now), survival/normal. To lock it down later,
# set ENABLE_WHITELIST = "TRUE" and WHITELIST = "name1,name2" and switch.
# No ops yet: grant one from the server console with
#   sudo podman exec minecraft-create rcon-cli op <name>
# Keep ONLINE_MODE on -- with it off, anyone can join as any username,
# including an op's.
#
# How players get in:
#   game     games.gignsky.com:25565 (router forwards it here)
#   website  https://games.gignsky.com -> the separate front nginx (which
#            owns TLS) -> plain HTTP on spacedock:1801 (nginx below): join
#            instructions + mods.zip, rebuilt whenever the server's mods
#            folder changes, so clients always match the server.
#
# ONE-TIME SETUP outside this repo:
#   1. Router: forward TCP 25565 -> spacedock's LAN IP. DONE 2026-10-26.
#   2. Front nginx: a games.gignsky.com vhost proxying to
#      http://<spacedock LAN IP>:1801. Port 1801 is opened on spacedock's
#      firewall (LAN-facing; don't forward it on the router).
#   3. DNS: games.gignsky.com must resolve to the home WAN IP
#      (24.211.162.59) and be DNS only (grey cloud) -- Cloudflare's proxy
#      only carries HTTP, so an orange-cloud record breaks the game
#      connection. The *.gignsky.com wildcard already covers this. If the
#      record is ever proxied, move the game to its own grey-cloud name and
#      point an SRV record at it:
#        _minecraft._tcp.games.gignsky.com  SRV  0 5 25565 mc.gignsky.com
#      No DDNS is wired up: if the home IP changes, DNS has to follow it.
#
# Mods, versions and the Minecraft/NeoForge versions live in
# ./minecraft-create-modpack.nix, shared with the Prism Launcher client
# instance in home/gig/common/optional/minecraft-create.nix -- bump them
# there, then tell players to re-download mods.zip.
{
  lib,
  pkgs,
  ...
}:
let
  dataDir = "/var/lib/minecraft-create";
  webDir = "/var/lib/minecraft-create-web";
  # Plain-HTTP port for the website, behind the separate TLS-terminating nginx.
  webPort = 1801;
  modpack = import ./minecraft-create-modpack.nix;
  inherit (modpack) minecraftVersion neoforgeVersion;
  # Modrinth "slug:versionId" for the image.
  mods = map (m: "${m.slug}:${m.version}") modpack.mods;

  site = pkgs.writeTextDir "index.html" ''
    <!doctype html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>Lord Gig's Create Server</title>
      <style>
        body { font: 16px/1.5 system-ui, sans-serif; max-width: 40rem; margin: 2rem auto; padding: 0 1rem; }
        code { background: #8882; padding: 0 .3em; border-radius: 3px; }
        a.button { display: inline-block; padding: .6em 1.2em; background: #2b6cb0; color: #fff; border-radius: 6px; text-decoration: none; }
      </style>
    </head>
    <body>
      <h1>Lord Gig's Create Server</h1>
      <p>Minecraft Java ${minecraftVersion} with NeoForge ${neoforgeVersion} and the Create mod.</p>
      <p>Server address: <code>games.gignsky.com</code></p>
      <p><a class="button" href="/mods.zip">Download mods.zip</a></p>
      <h2>Joining with the official launcher</h2>
      <ol>
        <li>Install Java 21 if you don't have it (e.g.
          <a href="https://adoptium.net/temurin/releases/?version=21">Adoptium Temurin 21</a>);
          the NeoForge installer needs it to run.</li>
        <li>Download the NeoForge <code>${neoforgeVersion}</code> installer from
          <a href="https://maven.neoforged.net/releases/net/neoforged/neoforge/${neoforgeVersion}/neoforge-${neoforgeVersion}-installer.jar">maven.neoforged.net</a>,
          run it, and choose <em>Install client</em>.</li>
        <li>Open your <code>.minecraft</code> folder (Windows: <code>%appdata%\.minecraft</code>), make a
          <code>mods</code> folder if there isn't one, empty it, and unzip <code>mods.zip</code> into it.</li>
        <li>In the launcher, pick the <em>neoforge</em> profile, press Play, then
          Multiplayer &rarr; Add Server &rarr; <code>games.gignsky.com</code>.</li>
      </ol>
      <p>When the server's mods change, download mods.zip again and replace the contents of your mods folder.</p>
    </body>
    </html>
  '';
in
{
  virtualisation.oci-containers.containers.minecraft-create = {
    # Pinned by digest (java21 tag, built 2026-10-25) for the same reason as
    # floatplane-wan-show.nix: `pull = "missing"` never refreshes a tag. Bump:
    #   nix run nixpkgs#skopeo -- inspect --no-tags docker://docker.io/itzg/minecraft-server:java21 | jq -r .Digest
    image = "docker.io/itzg/minecraft-server@sha256:ac1587a3c2d8f44a7e13188f66067453890dc1da301a54cd5b71d572602df05f";
    autoStart = true;
    environment = {
      TZ = "America/New_York";
      EULA = "TRUE";
      TYPE = "NEOFORGE";
      VERSION = minecraftVersion;
      NEOFORGE_VERSION = neoforgeVersion;
      MODRINTH_PROJECTS = lib.concatStringsSep "," mods;
      # The modpack lists every dependency itself, so the server runs exactly
      # the jars the client instance gets; a missing one fails loudly at
      # NeoForge load instead of being fetched here and drifting.
      MODRINTH_DOWNLOAD_DEPENDENCIES = "none";
      # mezzconfig only publishes betas; with release-only (the default) the
      # server once failed to resolve it and exited. Kept as a safeguard.
      MODRINTH_ALLOWED_VERSION_TYPE = "beta";
      # JVM heap. spacedock has ~15 GB shared with tdarr, pihole, etc.
      MEMORY = "6G";
      USE_AIKAR_FLAGS = "TRUE";
      MOTD = "Lord Gig's Create Server";
      MODE = "survival";
      DIFFICULTY = "normal";
      ONLINE_MODE = "TRUE";
      ENABLE_WHITELIST = "FALSE";
      # Create contraptions and elevators trip vanilla's flight check and
      # kick riders; this is the usual setting for Create servers.
      ALLOW_FLIGHT = "TRUE";
      VIEW_DISTANCE = "10";
    };
    volumes = [ "${dataDir}:/data" ];
    ports = [ "25565:25565/tcp" ];
    # The image saves the world on SIGTERM; give it time to finish rather
    # than podman's default 10 s.
    extraOptions = [ "--stop-timeout=120" ];
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      25565
      webPort
    ];
  };

  systemd = {
    # The image runs as uid/gid 1000 and owns its data dir.
    tmpfiles.rules = [
      "d ${dataDir} 0750 1000 1000 -"
      "d ${webDir} 0755 root root -"
    ];

    services.podman-minecraft-create.serviceConfig = {
      TimeoutStopSec = lib.mkForce 180;
      # The default 100ms restart hammers Modrinth when a mod fails to resolve.
      RestartSec = "30s";
    };

    # mods.zip for the website: every jar the server is running, so a client
    # that unzips it is guaranteed to match. Written to a temp name and moved
    # into place so a download never sees a half-written zip.
    services.minecraft-create-modzip = {
      description = "Rebuild mods.zip for the Create server website";
      serviceConfig.Type = "oneshot";
      path = [ pkgs.zip ];
      script = ''
        # Debounce: the path unit fires once per jar while the server is still
        # downloading, so let the folder settle before zipping it.
        sleep 30
        shopt -s nullglob
        jars=(${dataDir}/mods/*.jar)
        [ ''${#jars[@]} -gt 0 ] || exit 0
        rm -f ${webDir}/mods.zip.tmp
        zip -jq ${webDir}/mods.zip.tmp "''${jars[@]}"
        chmod 0644 ${webDir}/mods.zip.tmp
        mv ${webDir}/mods.zip.tmp ${webDir}/mods.zip
      '';
    };
    paths.minecraft-create-modzip = {
      wantedBy = [ "multi-user.target" ];
      pathConfig.PathChanged = "${dataDir}/mods";
    };
  };

  services.nginx = {
    enable = true;
    virtualHosts."minecraft-create-site" = {
      listen = [
        {
          addr = "0.0.0.0";
          port = webPort;
        }
      ];
      root = site;
      locations."= /mods.zip".alias = "${webDir}/mods.zip";
    };
  };
}
