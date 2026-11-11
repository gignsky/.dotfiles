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
#   game     games.gignsky.com:25565 (router forwards it here; its NAT
#            loopback makes the name work from the LAN too)
#   website  https://games.gignsky.com/minecraft/ -> the separate front
#            nginx (which owns TLS) -> plain HTTP on spacedock:1801, where
#            the shared `games-site` nginx vhost (games-site.nix) serves the
#            hub page at `/` and this file's locations below for everything
#            under /minecraft/, plus two ways to get the mods:
#              create-server.zip  a Prism Launcher instance whose pre-launch
#                                 command runs packwiz-installer against
#                                 /pack/pack.toml, so it syncs its mods to
#                                 the server's on every launch
#              mods.zip           fallback for other launchers: every jar
#                                 the server is running, rebuilt whenever
#                                 its mods folder changes
#
# ONE-TIME SETUP outside this repo:
#   1. Router: forward TCP 25565 -> spacedock's LAN IP. DONE 2026-10-26.
#   2. Front nginx: a games.gignsky.com vhost proxying to
#      http://<spacedock LAN IP>:1801. Port 1801 is opened on spacedock's
#      firewall by games-site.nix (LAN-facing; don't forward it on the
#      router). The Space Engineers server's own page lives at
#      /space-engineers/ on the same vhost (see space-engineers.nix).
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
# there and switch. Prism players pick it up on their next launch; anyone on
# mods.zip has to re-download it. A NeoForge bump is the exception: packwiz
# only syncs files, so Prism players change the NeoForge version in Edit
# Instance -> Version themselves (or re-import create-server.zip).
{
  lib,
  pkgs,
  ...
}:
let
  dataDir = "/var/lib/minecraft-create";
  webDir = "/var/lib/minecraft-create-web";
  gamePort = 25565;
  modpack = import ./minecraft-create-modpack.nix;
  inherit (modpack) minecraftVersion neoforgeVersion;
  # Modrinth "slug:versionId" for the image.
  mods = map (m: "${m.slug}:${m.version}") modpack.mods;

  # <li> download links for the website's optional extras.
  links = lib.concatMapStrings (p: ''<li><a href="${p.url}">${p.name or p.file}</a></li>'');

  siteUrl = "https://games.gignsky.com";

  # The packwiz pack, generated from the modpack file: one .pw.toml metafile
  # per entry, pointing at Modrinth's CDN (nothing is re-hosted), plus
  # index.toml and pack.toml with their hashes. packwiz-installer downloads
  # what changed and deletes what was dropped from the index.
  toml = pkgs.formats.toml { };
  pwFile = dir: side: option: m: {
    path = "${dir}/${lib.strings.sanitizeDerivationName (m.slug or m.name)}.pw.toml";
    source = toml.generate "pw.toml" (
      {
        name = m.name or m.slug;
        filename = m.file;
        inherit side;
        download = {
          inherit (m) url;
          hash-format = "sha512";
          hash = m.sha512;
        };
      }
      # Optional files get a checkbox in the installer's first-run dialog.
      // lib.optionalAttrs (option != null) {
        option = {
          optional = true;
        }
        // option;
      }
    );
  };
  packFiles =
    map (pwFile "mods" "both" null) modpack.mods
    ++ map (pwFile "mods" "client" {
      default = true;
      description = "Sodium/Iris: faster rendering and shader support (client only).";
    }) modpack.clientMods
    ++ map (pwFile "shaderpacks" "client" {
      default = false;
      description = "Shader pack; needs Sodium and Iris. Pick it under Video Settings -> Shader Packs.";
    }) modpack.shaderpacks
    ++ map (pwFile "resourcepacks" "client" {
      default = false;
      description = "Resource pack; enable it under Options -> Resource Packs.";
    }) modpack.resourcepacks;
  pack = pkgs.runCommand "minecraft-create-packwiz" { } ''
    mkdir -p $out
    cd $out
    ${lib.concatMapStrings (f: ''
      install -Dm644 ${f.source} "${f.path}"
    '') packFiles}
    {
      echo 'hash-format = "sha256"'
      for f in ${lib.escapeShellArgs (map (f: f.path) packFiles)}; do
        printf '\n[[files]]\nfile = "%s"\nhash = "%s"\nmetafile = true\n' \
          "$f" "$(sha256sum "$f" | cut -d' ' -f1)"
      done
    } > index.toml
    hash=$(sha256sum index.toml | cut -d' ' -f1)
    cat > pack.toml <<EOF
    name = "Lord Gig's Create Server"
    author = "Lord Gig"
    version = "${minecraftVersion}-''${hash:0:8}"
    pack-format = "packwiz:1.1.0"

    [index]
    file = "index.toml"
    hash-format = "sha256"
    hash = "$hash"

    [versions]
    minecraft = "${minecraftVersion}"
    neoforge = "${neoforgeVersion}"
    EOF
  '';

  # The Prism instance players import: Minecraft + NeoForge pinned like the
  # server, and a pre-launch command that runs the bootstrap (which fetches
  # packwiz-installer itself) to sync the mods before each launch.
  packwizBootstrap = pkgs.fetchurl {
    url = "https://github.com/packwiz/packwiz-installer-bootstrap/releases/download/v0.0.3/packwiz-installer-bootstrap.jar";
    hash = "sha256-qPuyTcYEJ46X9GiOgtPZGjGLmO/AjV2/y8vKtkQ9EWw=";
  };
  instanceMmcPack = pkgs.writeText "mmc-pack.json" (
    builtins.toJSON {
      formatVersion = 1;
      components = [
        {
          uid = "net.minecraft";
          version = minecraftVersion;
          important = true;
        }
        {
          uid = "net.neoforged";
          version = neoforgeVersion;
        }
      ];
    }
  );
  # Written by hand rather than with lib.generators.toINI: Prism reads it
  # with QSettings, so the quotes around $INST_JAVA (needed when the Java
  # path has spaces, as on Windows) must be escaped inside a quoted value.
  instanceCfg = pkgs.writeText "instance.cfg" ''
    [General]
    ConfigVersion=1.2
    InstanceType=OneSix
    name=Lord Gig's Create Server
    iconKey=default
    OverrideMemory=true
    MinMemAlloc=1024
    MaxMemAlloc=6144
    OverrideCommands=true
    PreLaunchCommand="\"$INST_JAVA\" -jar packwiz-installer-bootstrap.jar ${siteUrl}/pack/pack.toml"
  '';
  instanceZip = pkgs.runCommand "create-server.zip" { nativeBuildInputs = [ pkgs.zip ]; } ''
    mkdir -p inst/minecraft
    cp ${instanceCfg} inst/instance.cfg
    cp ${instanceMmcPack} inst/mmc-pack.json
    cp ${packwizBootstrap} inst/minecraft/packwiz-installer-bootstrap.jar
    cd inst
    zip -qrX $out .
  '';

  # netavark sometimes misses its teardown when the container goes down (seen
  # 2026-10-29 after a switch): the old container's DNAT rule for the game port
  # stays behind, sits ahead of the new one, and sends every connection to a
  # dead 10.88.x.x address -- clients hang on "Connecting to the server...".
  # Runs before each start, when no live container owns the port, so every
  # NETAVARK nat rule for it is stale; netavark re-adds the real ones on start.
  clearStaleDnat = pkgs.writeShellApplication {
    name = "minecraft-create-clear-stale-dnat";
    runtimeInputs = [
      pkgs.iptables
      pkgs.gnugrep
    ];
    text = ''
      # No match is the normal case; don't let grep's exit 1 fail the start.
      iptables-save -t nat |
        { grep -E -- "^-A NETAVARK[^ ]* .*--dport ${toString gamePort}( |$)" || true; } |
        while IFS= read -r rule; do
          echo "removing stale rule: $rule"
          eval "iptables -t nat ''${rule/#-A/-D}" || true
        done
    '';
  };

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
      <p><a href="/">&larr; all servers</a></p>
      <h1>Lord Gig's Create Server</h1>
      <p>Minecraft Java ${minecraftVersion} with NeoForge ${neoforgeVersion}, the Create mod, Stargate Journey
        and The Time Vortex (TARDIS).</p>
      <p>Server address: <code>games.gignsky.com</code></p>
      <h2>Joining with Prism Launcher (recommended)</h2>
      <p>The instance keeps its mods in sync with the server by itself: every time you press Launch it
        downloads whatever changed, so you never have to re-download anything.</p>
      <ol>
        <li>Install <a href="https://prismlauncher.org/download/">Prism Launcher</a> and sign in with the
          Microsoft account that owns Minecraft.</li>
        <li>Add Instance &rarr; Import, paste <code>${siteUrl}/create-server.zip</code>
          (or <a href="/create-server.zip">download it</a> and pick the file), then OK.</li>
        <li>Launch it. The first launch shows a list of optional extras (Sodium/Iris, shader packs,
          resource packs), then downloads the mods; later launches only fetch what changed.</li>
        <li>Multiplayer &rarr; Add Server &rarr; <code>games.gignsky.com</code>.</li>
      </ol>
      <p>The instance asks for 6 GB of memory; lower it under Edit &rarr; Settings &rarr; Java if your
        computer has 8 GB or less. To change the optional extras later, delete <code>packwiz.json</code>
        in the instance's <code>minecraft</code> folder and launch again.</p>
      <h2>Joining with the official launcher</h2>
      <p><a class="button" href="/mods.zip">Download mods.zip</a></p>
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
      <p>When the server's mods change, download mods.zip again and replace the contents of your mods folder
        (then put the shader mods below back, if you use them).</p>
      <h2>Optional: shaders</h2>
      <p>Shader packs need these two mods, client side only. Drop both jars into your <code>mods</code>
        folder next to the ones from mods.zip; the server doesn't have or need them.</p>
      <ul>${links modpack.clientMods}</ul>
      <p>Then put a shader pack zip (don't unzip it) in <code>.minecraft/shaderpacks</code> and pick it under
        Options &rarr; Video Settings &rarr; Shader Packs.</p>
      <ul>${links modpack.shaderpacks}</ul>
      <h2>Optional: resource packs</h2>
      <p>Put the zip (don't unzip it) in <code>.minecraft/resourcepacks</code> and enable it under
        Options &rarr; Resource Packs. No extra mods needed.</p>
      <ul>${links modpack.resourcepacks}</ul>
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
      # The world. SEED only applies when LEVEL's folder is first generated,
      # so a new seed means a new LEVEL name too; old worlds stay in
      # ${dataDir} (the first one is "world"). Reset 2026-10-30 so Stargate
      # Journey's gates generate.
      LEVEL = "world-stargate";
      SEED = "1819714931898554571";
    };
    volumes = [ "${dataDir}:/data" ];
    ports = [ "${toString gamePort}:${toString gamePort}/tcp" ];
    # The image saves the world on SIGTERM; give it time to finish rather
    # than podman's default 10 s.
    extraOptions = [ "--stop-timeout=120" ];
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      gamePort
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
      # Appended after oci-containers' own pre-start, which removes the old
      # container.
      ExecStartPre = [ "${clearStaleDnat}/bin/minecraft-create-clear-stale-dnat" ];
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

  # Contributes to the shared `games-site` vhost owned by games-site.nix
  # (hub page at `/`, listening on :1801) rather than defining its own vhost.
  services.nginx.virtualHosts."games-site".locations = {
    "/minecraft/".alias = "${site}/";
    "= /mods.zip".alias = "${webDir}/mods.zip";
    "= /create-server.zip".alias = instanceZip;
    # Revalidate each time so a launch right after a switch sees the new
    # pack rather than a cached pack.toml.
    "/pack/" = {
      alias = "${pack}/";
      extraConfig = "add_header Cache-Control no-cache;";
    };
  };
}
