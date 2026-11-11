# Space Engineers dedicated server, run as a service on spacedock.
#
# Keen only ships the server for Windows, so it runs under Wine inside the
# `devidian/spaceengineers` image (Debian 12 + WineHQ staging + SteamCMD, with
# the winetricks the server needs already baked in; rebuilt upstream 2026-09).
# The image's own entrypoint expects an instance that was first created with
# the Windows GUI tool, so it is NOT used. The entrypoint below (a store file
# bind-mounted into the container) installs/updates the game with SteamCMD on
# every start, seeds a config the first time, and lets the server generate its
# first world from one of Keen's bundled scenarios. Everything stateful lives
# under /var/lib/space-engineers.
#
# Layout (host -> container; the image hardcodes /appdata/space-engineers):
#   /var/lib/space-engineers/game       SteamCMD install of app 298740 (~8 GB)
#   /var/lib/space-engineers/instances  one dir per instance: config, Saves/, logs
#   /var/lib/space-engineers/plugins    drop .dll plugins here; added to the config on start
#   /var/lib/space-engineers/steamcmd   SteamCMD itself and its state
#   /var/lib/space-engineers/wine       the Wine prefix (copied from the image on first
#                                       start, then given the VC++ x64 runtime; see below)
#   /var/lib/space-engineers/password-salt  persisted PBKDF2 salt; see configSync below
#
# The rendered website (index.html with the live password) lives separately
# at /var/lib/space-engineers-web, NOT under /var/lib/space-engineers -- that
# directory is 0750 root-only, so nginx (its own unprivileged user) couldn't
# even traverse into it to reach a nested web/ subdir (403, found the hard
# way after the first deploy). Same split as minecraft-create.nix's
# dataDir/webDir.
#
# Ports: UDP 27016 (game) and UDP 8766 (Steam) are opened on the LAN firewall
# and the container shares the host network stack, so the server is reachable
# at spacedock:27016 on the LAN. Public internet play (the chosen setup, for
# NISC members) needs both forwarded on the router to spacedock's LAN IP:
# UDP 27016 (the game) and UDP 8766 (Steam's query port, so the server shows
# up correctly -- name/ping/player count -- in the public server browser,
# since OnlineMode is PUBLIC). Server address: games.gignsky.com:27016.
#
# Website: https://games.gignsky.com/space-engineers/ (one page of the shared
# `games-site` nginx vhost -- see games-site.nix for the hub and
# minecraft-create.nix for the Minecraft page) shows the connect info and the
# current password, rendered from `webTemplate` below by configSync.
#
# Password: the server is public (discoverable on Steam's server list) but
# password-gated. Required because MyConfigDedicated has no plaintext
# password field -- only <ServerPasswordHash>/<ServerPasswordSalt>, which
# configSync computes from the `space-engineers/password` sops secret on
# every start (see that script's own header comment for the algorithm and
# its caveats) and writes into both the live cfg and the website. Rotate
# the password by changing the sops secret and running `systemctl restart
# podman-space-engineers`.
#
# Settings: the cfg is seeded from the template below only when it does not
# exist, so after the first start the copy on disk is normally the source of
# truth -- EXCEPT for the fields in `enforcedFields` (game mode, multipliers,
# research, max players, administrators -- the same set `settingsList` draws
# from for the website), which configSync re-applies on every start,
# specifically so changing one of those bindings and rebuilding is enough:
# no need to delete and re-seed the whole file. Anything NOT in
# `enforcedFields` (ServerDescription, MessageOfTheDay, a tweak made through
# the in-game admin menu, ...) is left alone and persists across restarts.
# <LoadWorld> and <Plugins> are rewritten on every start too, but by the
# entrypoint, not configSync -- see there for why.
#
# Admins: `administratorSteamIds` above, enforced the same way -- change it
# and `just rebuild` is enough; no re-seed needed.
#
# Stop/restart is graceful: the entrypoint turns SIGTERM into a Ctrl+C event
# for the server, which saves and exits (verified), and the unit waits up to
# 3 minutes for it. A nightly timer
# restarts the service, which is also how game updates are picked up.
{
  lib,
  pkgs,
  config,
  ...
}:
let
  serverName = "Spacedock";
  worldName = "Spacedock";
  # Scenario the first world is generated from: a folder under
  # Content/CustomWorlds in the server install ("Star System", "Empty World",
  # ...). Only consulted until a save exists in the instance.
  scenario = "Star System";
  maxPlayers = 8;
  # Steam ID64s with in-game admin powers (kick/ban, unlimited build
  # distance, etc.). Not secret -- a Steam ID is public info -- so these are
  # plain literals rather than a sops secret.
  administratorSteamIds = [
    "76561198080701800" # gig
    "76561198969018039" # Evan
  ];
  # Gameplay settings worth telling players about before they join -- named
  # here (rather than only as literals in the XML template below) so the
  # website's settings list can't drift from what the server actually runs;
  # see `settingsList` and its use in `webTemplate`.
  gameMode = "Survival";
  onlineMode = "PUBLIC";
  environmentHostility = "NORMAL";
  resourceMultiplier = 3; # inventory size, assembler speed/efficiency, refinery speed
  toolSpeedMultiplier = 2; # welder, grinder
  enableOxygen = true;
  enableResearch = false;
  enableEconomy = true;
  enableRadiation = true;
  proceduralDensity = 0.35; # asteroid density
  gamePort = 27016;
  steamPort = 8766;
  instanceName = "spacedock";
  stateDir = "/var/lib/space-engineers";
  # Separate from stateDir (0750, root-only) and world-readable instead, so
  # nginx (running as its own unprivileged user) can actually traverse into
  # it -- same split as minecraft-create.nix's dataDir/webDir.
  webDir = "/var/lib/space-engineers-web";
  appdata = "/appdata/space-engineers";
  # Nightly restart (saves, exits, SteamCMD applies any game update on the way
  # back up). systemd.time(7) calendar expression, local time.
  restartCalendar = "*-*-* 05:00:00";
  # Hard memory cap. Spacedock has 15 GiB and no swap, so a leaking server gets
  # OOM-killed and restarted instead of taking the host (and the binary cache
  # builder) down with it. Keen recommends 10 GB.
  memoryLimit = "10g";

  # Wine maps the container's / to Z:\.
  winPath = p: "Z:" + lib.replaceStrings [ "/" ] [ "\\" ] p;

  onOff = v: if v then "On" else "Off";

  # Shown on the website so players know the rules before joining. Pulled
  # from the same named bindings above that build the XML, not hand-copied,
  # so this can't quietly drift from what the server actually runs.
  settingsList = [
    {
      label = "Game mode";
      value = gameMode;
    }
    {
      label = "Max players";
      value = toString maxPlayers;
    }
    {
      label = "Starting scenario";
      value = scenario;
    }
    {
      label = "Environment hostility";
      value = environmentHostility;
    }
    {
      label = "Inventory/assembler/refinery rates";
      value = "${toString resourceMultiplier}x";
    }
    {
      label = "Welder/grinder speed";
      value = "${toString toolSpeedMultiplier}x";
    }
    {
      label = "Oxygen";
      value = onOff enableOxygen;
    }
    {
      label = "Research";
      value = onOff enableResearch;
    }
    {
      label = "Economy";
      value = onOff enableEconomy;
    }
    {
      label = "Radiation";
      value = onOff enableRadiation;
    }
    {
      label = "Asteroid density";
      value = builtins.toJSON proceduralDensity;
    }
  ];

  # Re-applied to the live cfg on every start (by configSync below), keyed by
  # the cfg's exact XML tag with the value already rendered as that
  # element's inner text. This is what lets "change a binding, rebuild"
  # actually take effect on an already-seeded server instead of silently
  # doing nothing until someone remembers to re-seed the file by hand.
  # Deliberately NOT everything in the cfg -- only what's named as a Nix
  # binding above, same set `settingsList` draws from, plus Administrators.
  # Anything else (ServerDescription, MessageOfTheDay, a setting tweaked via
  # the in-game admin menu, ...) is left alone and persists across restarts.
  enforcedFields = {
    GameMode = gameMode;
    OnlineMode = onlineMode;
    EnvironmentHostility = environmentHostility;
    InventorySizeMultiplier = toString resourceMultiplier;
    AssemblerSpeedMultiplier = toString resourceMultiplier;
    AssemblerEfficiencyMultiplier = toString resourceMultiplier;
    RefinerySpeedMultiplier = toString resourceMultiplier;
    WelderSpeedMultiplier = toString toolSpeedMultiplier;
    GrinderSpeedMultiplier = toString toolSpeedMultiplier;
    EnableOxygen = lib.boolToString enableOxygen;
    EnableResearch = lib.boolToString enableResearch;
    EnableEconomy = lib.boolToString enableEconomy;
    EnableRadiation = lib.boolToString enableRadiation;
    ProceduralDensity = builtins.toJSON proceduralDensity;
    MaxPlayers = toString maxPlayers;
    Administrators = lib.concatMapStrings (id: "<string>${id}</string>") administratorSteamIds;
  };

  # Status check: NOT a protocol query -- tried Valve's A2S_INFO first
  # (Steam's own server browser can list the server), but confirmed by hand
  # against the real deployed server that nothing answers it on the Steam
  # port: Space Engineers is Keen's own VRage engine, not Source engine, and
  # doesn't speak that wire protocol despite Steam being able to list it
  # some other way. Keen's actual answer is the Dedicated Server's Remote
  # API (<RemoteApiEnabled>/<RemoteApiPort>, currently off), but its
  # HTTP auth is an undocumented HMAC+timestamp scheme -- not worth guessing
  # at a second time. So: just ask systemd whether the unit is active. No
  # player count this way, only online/offline, but it's actually correct
  # instead of plausible-looking and wrong.
  statusCheck = pkgs.writeShellApplication {
    name = "space-engineers-status-check";
    runtimeInputs = [ pkgs.systemd ];
    text = ''
      if systemctl is-active --quiet podman-space-engineers.service; then
        online=true
      else
        online=false
      fi
      printf '{"online": %s}' "$online" > ${webDir}/status.json.tmp
      mv ${webDir}/status.json.tmp ${webDir}/status.json
    '';
  };

  # Seed config. <SessionSettings> mirrors the <Settings> block of Keen's "Star
  # System" scenario (Content/CustomWorlds/Star System/Sandbox.sbc, game
  # 01_210), with OnlineMode/MaxPlayers overridden; the config's settings are
  # applied to the world on every start, and anything left out would fall back
  # to engine defaults (e.g. ProceduralDensity 0 = no asteroids).
  defaultConfig = pkgs.writeText "SpaceEngineers-Dedicated.cfg" ''
    <?xml version="1.0"?>
    <MyConfigDedicated xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <SessionSettings>
        <GameMode>${gameMode}</GameMode>
        <InventorySizeMultiplier>${toString resourceMultiplier}</InventorySizeMultiplier>
        <AssemblerSpeedMultiplier>${toString resourceMultiplier}</AssemblerSpeedMultiplier>
        <AssemblerEfficiencyMultiplier>${toString resourceMultiplier}</AssemblerEfficiencyMultiplier>
        <RefinerySpeedMultiplier>${toString resourceMultiplier}</RefinerySpeedMultiplier>
        <OnlineMode>${onlineMode}</OnlineMode>
        <MaxPlayers>${toString maxPlayers}</MaxPlayers>
        <MaxFloatingObjects>100</MaxFloatingObjects>
        <MaxBackupSaves>5</MaxBackupSaves>
        <MaxGridSize>0</MaxGridSize>
        <MaxBlocksPerPlayer>0</MaxBlocksPerPlayer>
        <TotalPCU>100000</TotalPCU>
        <MaxFactionsCount>0</MaxFactionsCount>
        <BlockLimitsEnabled>GLOBALLY</BlockLimitsEnabled>
        <EnableRemoteBlockRemoval>true</EnableRemoteBlockRemoval>
        <EnvironmentHostility>${environmentHostility}</EnvironmentHostility>
        <AutoHealing>true</AutoHealing>
        <EnableCopyPaste>false</EnableCopyPaste>
        <WeaponsEnabled>true</WeaponsEnabled>
        <ShowPlayerNamesOnHud>true</ShowPlayerNamesOnHud>
        <ThrusterDamage>true</ThrusterDamage>
        <EnableSpectator>false</EnableSpectator>
        <WorldSizeKm>0</WorldSizeKm>
        <MinimumWorldSize>6000</MinimumWorldSize>
        <RespawnShipDelete>false</RespawnShipDelete>
        <ResetOwnership>false</ResetOwnership>
        <WelderSpeedMultiplier>${toString toolSpeedMultiplier}</WelderSpeedMultiplier>
        <GrinderSpeedMultiplier>${toString toolSpeedMultiplier}</GrinderSpeedMultiplier>
        <RealisticSound>false</RealisticSound>
        <HackSpeedMultiplier>0.33</HackSpeedMultiplier>
        <PermanentDeath>false</PermanentDeath>
        <AutoSaveInMinutes>5</AutoSaveInMinutes>
        <SpawnShipTimeMultiplier>0</SpawnShipTimeMultiplier>
        <ProceduralDensity>${builtins.toJSON proceduralDensity}</ProceduralDensity>
        <RandomizeSeed>true</RandomizeSeed>
        <ProceduralSeed>0</ProceduralSeed>
        <DestructibleBlocks>true</DestructibleBlocks>
        <EnableIngameScripts>false</EnableIngameScripts>
        <ViewDistance>15000</ViewDistance>
        <FloraDensity>20</FloraDensity>
        <EnableToolShake>false</EnableToolShake>
        <EnableOxygen>${lib.boolToString enableOxygen}</EnableOxygen>
        <EnableResearch>${lib.boolToString enableResearch}</EnableResearch>
        <EnableOxygenPressurization>true</EnableOxygenPressurization>
        <Enable3rdPersonView>true</Enable3rdPersonView>
        <EnableFlora>true</EnableFlora>
        <EnableConvertToStation>true</EnableConvertToStation>
        <StationVoxelSupport>false</StationVoxelSupport>
        <EnableSunRotation>true</EnableSunRotation>
        <EnableRespawnShips>true</EnableRespawnShips>
        <ScenarioEditMode>false</ScenarioEditMode>
        <Scenario>false</Scenario>
        <CanJoinRunning>false</CanJoinRunning>
        <PhysicsIterations>8</PhysicsIterations>
        <SunRotationIntervalMinutes>119.999992</SunRotationIntervalMinutes>
        <EnableJetpack>true</EnableJetpack>
        <SpawnWithTools>true</SpawnWithTools>
        <StartInRespawnScreen>false</StartInRespawnScreen>
        <EnableVoxelDestruction>true</EnableVoxelDestruction>
        <MaxDrones>5</MaxDrones>
        <EnableWolfs>true</EnableWolfs>
        <EnableSpiders>true</EnableSpiders>
        <FloraDensityMultiplier>1</FloraDensityMultiplier>
        <EnableStructuralSimulation>false</EnableStructuralSimulation>
        <MaxActiveFracturePieces>50</MaxActiveFracturePieces>
        <BlockTypeLimits>
          <dictionary />
        </BlockTypeLimits>
        <EnableScripterRole>false</EnableScripterRole>
        <ExperimentalMode>false</ExperimentalMode>
        <EnableVoxelHand>true</EnableVoxelHand>
        <HasPlanets>true</HasPlanets>
        <EnableSpaceSuitRespawn>false</EnableSpaceSuitRespawn>
        <EnableEconomy>${lib.boolToString enableEconomy}</EnableEconomy>
        <DepositsCountCoefficient>1</DepositsCountCoefficient>
        <DepositSizeDenominator>60</DepositSizeDenominator>
        <HarvestRatioMultiplier>0.8</HarvestRatioMultiplier>
        <TradeFactionsCount>10</TradeFactionsCount>
        <ScrapEnabled>false</ScrapEnabled>
        <EnableRadiation>${lib.boolToString enableRadiation}</EnableRadiation>
        <SolarRadiationIntensity>0</SolarRadiationIntensity>
        <FoodConsumptionRate>0.5</FoodConsumptionRate>
        <EnableSurvivalBuffs>true</EnableSurvivalBuffs>
        <EnableReducedStatsOnRespawn>true</EnableReducedStatsOnRespawn>
      </SessionSettings>
      <LoadWorld />
      <IP>0.0.0.0</IP>
      <SteamPort>${toString steamPort}</SteamPort>
      <ServerPort>${toString gamePort}</ServerPort>
      <AsteroidAmount>0</AsteroidAmount>
      <Administrators>${
        lib.concatMapStrings (id: "<string>${id}</string>") administratorSteamIds
      }</Administrators>
      <Banned />
      <GroupID>0</GroupID>
      <!-- Rewritten on every start by configSync from the
           `space-engineers/password` sops secret; see that script's header. -->
      <ServerPasswordHash />
      <ServerPasswordSalt />
      <ServerName>${serverName}</ServerName>
      <WorldName>${worldName}</WorldName>
      <PauseGameWhenEmpty>true</PauseGameWhenEmpty>
      <MessageOfTheDay />
      <MessageOfTheDayUrl />
      <AutoRestartEnabled>false</AutoRestartEnabled>
      <AutoUpdateEnabled>false</AutoUpdateEnabled>
      <IgnoreLastSession>true</IgnoreLastSession>
      <PremadeCheckpointPath>${winPath "${appdata}/SpaceEngineersDedicated/Content/CustomWorlds/${scenario}"}</PremadeCheckpointPath>
      <ServerDescription />
      <Reserved />
      <RemoteApiEnabled>false</RemoteApiEnabled>
      <RemoteApiPort>8080</RemoteApiPort>
      <Plugins />
      <SaveChatToLog>true</SaveChatToLog>
    </MyConfigDedicated>
  '';

  # Public info page content, baked at eval time -- NOT the live file nginx
  # serves. `@SE_PASSWORD@` is substituted at runtime by configSync so the
  # plaintext password never lands in the Nix store.
  webTemplate = pkgs.writeText "space-engineers-index.html" ''
    <!doctype html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>${serverName}: Space Engineers Server</title>
      <style>
        body { font: 16px/1.5 system-ui, sans-serif; max-width: 40rem; margin: 2rem auto; padding: 0 1rem; }
        code { background: #8882; padding: 0 .3em; border-radius: 3px; }
        .status.online { color: #2b8a3e; font-weight: 600; }
        .status.offline { color: #999; }
        .status.unknown { color: #d9822b; }
        table.settings { border-collapse: collapse; }
        table.settings td { padding: .15em .6em; }
        table.settings td:first-child { color: #666; }
      </style>
    </head>
    <body>
      <p><a href="/">&larr; all servers</a></p>
      <h1>${serverName}: Space Engineers Server</h1>
      <p>Status: <span id="se-status" class="status">checking&hellip;</span></p>
      <p>Started from the "${scenario}" scenario.</p>
      <h2>Settings</h2>
      <table class="settings">
        ${lib.concatMapStrings (s: ''
          <tr><td>${s.label}</td><td>${s.value}</td></tr>
        '') settingsList}
      </table>
      <h2>Joining</h2>
      <p>In Space Engineers: Multiplayer &rarr; Join World &rarr; search the public server list
        for <strong>${serverName}</strong>, then enter this password when prompted:</p>
      <p><code>@SE_PASSWORD@</code></p>
      <p>For NISC members only &mdash; please don't share it further. If the server doesn't show
        up in the list (NAT/firewall hiccups happen), the direct address is
        <code>games.gignsky.com:${toString gamePort}</code> (UDP).</p>
      <p>The server pauses the simulation whenever no one is connected, so it's fine to leave
        the save loaded between sessions.</p>
      <script src="/status.js"></script>
      <script>pollStatus("/space-engineers/status.json", "se-status");</script>
    </body>
    </html>
  '';

  # PBKDF2-HMAC-SHA1(password, salt, 10000 iters, 20-byte key), both
  # base64-encoded into <ServerPasswordHash>/<ServerPasswordSalt> -- the
  # dedicated server has no plaintext password field, and this encoding is
  # community-reverse-engineered (Keen's own Windows "Dedicated Server" GUI
  # tool is the only thing that officially computes it; see
  # privatesourcetech/se-shipyard and Stark-52/se-server-macos). Untested
  # against a real client connect as of writing -- verify by actually joining
  # with the password after the first deploy. If it doesn't work, the
  # fallback is running that GUI tool once on a Windows box and pasting its
  # two generated lines into the live cfg below by hand.
  #
  # The salt is generated once and persisted at /var/lib/space-engineers/password-salt
  # so re-running this with an unchanged password reproduces the same hash
  # instead of needlessly rewriting the cfg on every start.
  configSyncPy = pkgs.writeText "space-engineers-config-sync.py" ''
    import base64
    import hashlib
    import json
    import os
    import re
    import shutil
    import sys

    password_file, cfg_path, seed_path, salt_path, web_template_path, web_out_path, enforced_fields_json = sys.argv[1:8]
    enforced_fields = json.loads(enforced_fields_json)

    with open(password_file) as f:
        password = f.read().strip()

    if not os.path.exists(cfg_path):
        os.makedirs(os.path.dirname(cfg_path), exist_ok=True)
        shutil.copy(seed_path, cfg_path)

    if os.path.exists(salt_path):
        with open(salt_path) as f:
            salt = base64.b64decode(f.read().strip())
    else:
        salt = os.urandom(16)
        tmp = salt_path + ".tmp"
        with open(tmp, "w") as f:
            f.write(base64.b64encode(salt).decode())
        os.replace(tmp, salt_path)

    digest = hashlib.pbkdf2_hmac("sha1", password.encode("utf-8"), salt, 10000, dklen=20)
    hash_b64 = base64.b64encode(digest).decode()
    salt_b64 = base64.b64encode(salt).decode()

    with open(cfg_path) as f:
        cfg = f.read()

    def setelem(cfg, tag, value):
        pattern = re.compile(r"<" + tag + r"\s*/>|<" + tag + r">.*?</" + tag + r">", re.DOTALL)
        if not pattern.search(cfg):
            raise SystemExit(f"{tag} element not found in {cfg_path}; template out of sync")
        return pattern.sub(f"<{tag}>{value}</{tag}>", cfg, count=1)

    cfg = setelem(cfg, "ServerPasswordHash", hash_b64)
    cfg = setelem(cfg, "ServerPasswordSalt", salt_b64)

    # Nix-managed settings always win on disk; anything not in this dict
    # (set by hand, or via the in-game admin menu) is left untouched.
    for tag, value in enforced_fields.items():
        cfg = setelem(cfg, tag, value)

    tmp_cfg = cfg_path + ".tmp"
    with open(tmp_cfg, "w") as f:
        f.write(cfg)
    os.replace(tmp_cfg, cfg_path)

    os.makedirs(os.path.dirname(web_out_path), exist_ok=True)
    with open(web_template_path) as f:
        page = f.read()
    page = page.replace("@SE_PASSWORD@", password)
    tmp_page = web_out_path + ".tmp"
    with open(tmp_page, "w") as f:
        f.write(page)
    os.chmod(tmp_page, 0o644)
    os.replace(tmp_page, web_out_path)
  '';

  configSync = pkgs.writeShellApplication {
    name = "space-engineers-config-sync";
    runtimeInputs = [ pkgs.python3 ];
    text = ''
      python3 ${configSyncPy} \
        "${config.sops.secrets."space-engineers/password".path}" \
        "${stateDir}/instances/${instanceName}/SpaceEngineers-Dedicated.cfg" \
        "${defaultConfig}" \
        "${stateDir}/password-salt" \
        "${webTemplate}" \
        "${webDir}/index.html" \
        ${lib.escapeShellArg (builtins.toJSON enforcedFields)}
    '';
  };

  # Runs as PID 1 in the container via /bin/bash (the image's bash, not the
  # store's), so no nix shebang.
  entrypoint = pkgs.writeText "space-engineers-entrypoint.sh" ''
    # Entrypoint for the space-engineers container.
    # Managed by containers/services/space-engineers.nix in .dotfiles.
    set -euo pipefail

    APPDATA=${appdata}
    GAME_DIR=$APPDATA/SpaceEngineersDedicated
    INSTANCE_DIR=$APPDATA/instances/$INSTANCE_NAME
    PLUGIN_DIR=$APPDATA/plugins
    CFG=$INSTANCE_DIR/SpaceEngineers-Dedicated.cfg
    SEED=/opt/se/SpaceEngineers-Dedicated.cfg
    EXE=$GAME_DIR/DedicatedServer64/SpaceEngineersDedicated.exe

    winpath() { local p=''${1//\//\\}; printf 'Z:%s' "$p"; }
    # Escape a sed replacement string (backslashes, &, and the = delimiter).
    sedesc() { local s=''${1//\\/\\\\}; s=''${s//&/\\&}; printf '%s' "''${s//=/\\=}"; }
    # Replace element $1 (self-closing or single-line) in $CFG with $2.
    setelem() { sed -i -E "s=<$1 */>|<$1>.*</$1>=$(sedesc "$2")=" "$CFG"; }

    # bash is PID 1 here, so without a handler SIGTERM is simply ignored and
    # podman has to SIGKILL after --stop-timeout. Bash also defers traps until
    # a foreground child exits, so long steps run backgrounded under `await`,
    # which `wait`s (interruptible) and lets the trap kill the child.
    child=""
    await() { "$@" & child=$!; local rc=0; wait "$child" || rc=$?; child=""; return "$rc"; }
    pre_stop() {
      echo "== stop requested before the server started"
      [ -n "$child" ] && kill "$child" 2>/dev/null
      exit 143
    }
    trap pre_stop TERM INT

    echo "== SteamCMD: install/update Space Engineers Dedicated Server (app 298740)"
    for attempt in 1 2 3; do
      # Platform type and install dir must be set before login, or SteamCMD
      # fails with "Missing configuration".
      if await /usr/games/steamcmd +@sSteamCmdForcePlatformType windows +force_install_dir "$GAME_DIR" \
           +login anonymous +app_update 298740 +quit \
         && [ -f "$EXE" ]; then
        break
      fi
      echo "steamcmd attempt $attempt did not produce the server binary, retrying in 20s"
      await sleep 20
    done
    if [ ! -f "$EXE" ]; then
      echo "server binary still missing after SteamCMD, giving up"
      exit 1
    fi

    echo "== wine prefix"
    # The image bakes its prefix at /root/server, but its vcrun2019 winetricks
    # step never actually installed anything, so the server dies on start with
    # "Please install latest C++ redistributable package for 2015-2019 x64"
    # (upstream issue #91). winetricks' vcrun2022 verb also aborts in this
    # image (its x86 half fails), so install Microsoft's x64 redistributable
    # directly. Keep the prefix on the host: seed it from the image's once,
    # patch it once, reuse it forever.
    export WINEPREFIX=$APPDATA/wine
    if [ ! -f "$WINEPREFIX/system.reg" ]; then
      echo "seeding $WINEPREFIX from the image's prefix"
      cp -a /root/server/. "$WINEPREFIX/"
    fi
    marker=$WINEPREFIX/.vc-redist-x64-installed
    if [ ! -f "$marker" ] && ! grep -q 'VC\\\\Runtimes\\\\X64' "$WINEPREFIX/system.reg"; then
      echo "installing the VC++ 2015-2022 x64 runtime into the prefix (one-time)"
      curl -fsSL -o /tmp/vc_redist.x64.exe https://aka.ms/vs/17/release/vc_redist.x64.exe
      rm -f /tmp/.X99-lock
      Xvfb :99 -screen 0 1024x768x16 >/dev/null 2>&1 &
      xvfb_pid=$!
      sleep 1
      # Synchronous; ~20 s. Do NOT `wineserver -w` afterwards: that waits for
      # the .NET native-image service the prefix boot spawns, which can take
      # 15+ minutes.
      DISPLAY=:99 await wine /tmp/vc_redist.x64.exe /install /quiet /norestart
      touch "$marker"
      kill "$xvfb_pid" 2>/dev/null || true
      rm -f /tmp/vc_redist.x64.exe
    fi

    echo "== config"
    mkdir -p "$INSTANCE_DIR/Saves" "$PLUGIN_DIR"
    if [ ! -f "$CFG" ]; then
      echo "seeding $CFG from the template"
      cp "$SEED" "$CFG"
    fi

    plugins=""
    for dll in "$PLUGIN_DIR"/*.dll; do
      [ -e "$dll" ] || continue
      plugins+="<string>$(winpath "$dll")</string>"
    done
    if [ -n "$plugins" ]; then
      echo "plugins: $plugins"
      setelem Plugins "<Plugins>$plugins</Plugins>"
    else
      setelem Plugins "<Plugins />"
    fi

    echo "== world"
    world_name=$(sed -n -E 's=.*<WorldName>(.*)</WorldName>.*=\1=p' "$CFG")
    save=""
    if [ -f "$INSTANCE_DIR/Saves/$world_name/Sandbox.sbc" ]; then
      save=$INSTANCE_DIR/Saves/$world_name
    else
      # Fall back to the newest save in the instance, whatever it is called,
      # so a server never generates a second world by accident.
      save=$(find "$INSTANCE_DIR/Saves" -mindepth 2 -maxdepth 2 -name Sandbox.sbc -printf '%T@ %h\n' 2>/dev/null \
             | sort -rn | head -1 | cut -d' ' -f2-)
    fi
    if [ -n "$save" ]; then
      echo "loading save: $save"
      setelem LoadWorld "<LoadWorld>$(winpath "$save")</LoadWorld>"
    else
      scenario=$(sed -n -E 's=.*<PremadeCheckpointPath>(.*)</PremadeCheckpointPath>.*=\1=p' "$CFG")
      scenario_dir=''${scenario#Z:}
      scenario_dir=''${scenario_dir//\\//}
      if [ ! -f "$scenario_dir/Sandbox.sbc" ]; then
        echo "no save yet and scenario '$scenario' is not in the server install. Available:"
        ls "$GAME_DIR/Content/CustomWorlds" || true
        exit 1
      fi
      echo "no save yet: generating '$world_name' from scenario $scenario"
      setelem LoadWorld "<LoadWorld />"
    fi

    echo "== starting server ($(wine --version))"
    cd "$GAME_DIR/DedicatedServer64"
    wine SpaceEngineersDedicated.exe -noconsole -ignorelastsession -path "$(winpath "$INSTANCE_DIR")" &
    se_pid=$!

    stop() {
      # Wine turns SIGINT on the server process into a console Ctrl+C event,
      # which the server handles by saving and shutting down (~1 s when
      # empty). taskkill does not work here: with -noconsole there is no
      # window for its WM_CLOSE. `wine foo.exe` runs the real process under a
      # start.exe wrapper, so find it by its Windows command line.
      echo "== stop requested: asking the server to save and exit"
      pid=$(pgrep -f '^Z:.*SpaceEngineersDedicated\.exe' | head -1 || true)
      kill -INT "''${pid:-$se_pid}" 2>/dev/null || true
      for i in $(seq 1 150); do
        kill -0 "$se_pid" 2>/dev/null || break
        sleep 1
      done
      if kill -0 "$se_pid" 2>/dev/null; then
        echo "server still running after 150s, sending SIGTERM"
        kill "$se_pid" 2>/dev/null || true
      fi
      wait "$se_pid" || true
      echo "== server stopped"
      exit 0
    }
    trap stop TERM INT

    rc=0
    wait "$se_pid" || rc=$?
    echo "== server exited with status $rc"
    exit "$rc"
  '';
in
{
  # Before the first switch, add to nix-secrets/secrets.yaml (`just sops`):
  #   space-engineers:
  #     password: <the shared passphrase for NISC members, shown on the website>
  # Rotate it the same way; the restart below regenerates the cfg's hash/salt
  # and the website's copy together.
  sops.secrets."space-engineers/password" = {
    restartUnits = [ "podman-space-engineers.service" ];
  };

  virtualisation.oci-containers.containers.space-engineers = {
    image = "docker.io/devidian/spaceengineers:winestaging";
    autoStart = true;
    entrypoint = "/bin/bash";
    cmd = [ "/opt/se/entrypoint.sh" ];
    environment = {
      TZ = "America/New_York";
      INSTANCE_NAME = instanceName;
      WINEDEBUG = "-all";
    };
    volumes = [
      "${stateDir}/game:${appdata}/SpaceEngineersDedicated"
      "${stateDir}/instances:${appdata}/instances"
      "${stateDir}/plugins:${appdata}/plugins"
      # The image's steamcmd wrapper installs SteamCMD under ~/.local/share/Steam
      # (and only symlinks ~/.steam to it), so persist that or it re-downloads
      # itself on every start.
      "${stateDir}/steamcmd:/root/.local/share/Steam"
      "${stateDir}/wine:${appdata}/wine"
      "${entrypoint}:/opt/se/entrypoint.sh:ro"
      "${defaultConfig}:/opt/se/SpaceEngineers-Dedicated.cfg:ro"
    ];
    extraOptions = [
      # Host networking: Steam's server browser and the game's UDP traffic
      # behave best without NAT, and it keeps the ports identical inside/out.
      "--network=host"
      "--memory=${memoryLimit}"
      # The image's HEALTHCHECK queries the Steam API for $PUBLIC_IP, which is
      # meaningless on a LAN box.
      "--no-healthcheck"
      # Let the save-and-exit in the entrypoint finish before podman kills it.
      "--stop-timeout=170"
    ];
  };

  systemd = {
    tmpfiles.rules = [
      "d ${stateDir} 0750 root root -"
      "d ${stateDir}/game 0750 root root -"
      "d ${stateDir}/instances 0750 root root -"
      "d ${stateDir}/plugins 0750 root root -"
      "d ${stateDir}/steamcmd 0750 root root -"
      "d ${stateDir}/wine 0750 root root -"
      "d ${webDir} 0755 root root -"
    ];

    services.podman-space-engineers.serviceConfig = {
      # The server exits cleanly on its own restarts/updates; always come back.
      Restart = lib.mkForce "always";
      RestartSec = "30s";
      TimeoutStopSec = lib.mkForce 180;
      # Rewrites the live cfg's password hash/salt (and the website's copy of
      # the plaintext password) from the sops secret before every start, so a
      # password rotation just needs `systemctl restart podman-space-engineers`.
      ExecStartPre = [ "${configSync}/bin/space-engineers-config-sync" ];
    };

    # Nightly restart = save + pick up game updates (SteamCMD runs on every start).
    services.space-engineers-restart = {
      description = "Nightly restart of the Space Engineers server (save + update)";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.systemd}/bin/systemctl try-restart podman-space-engineers.service";
      };
    };
    timers.space-engineers-restart = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = restartCalendar;
        Persistent = false;
      };
    };

    services.space-engineers-status-check = {
      description = "Poll the Space Engineers server's status for the website";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${statusCheck}/bin/space-engineers-status-check";
      };
    };
    timers.space-engineers-status-check = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "30s";
        OnUnitActiveSec = "30s";
      };
    };
  };

  networking.firewall = {
    enable = true;
    allowedUDPPorts = [
      gamePort
      steamPort
    ];
  };

  # Contributes to the shared `games-site` vhost owned by games-site.nix
  # (hub page at `/`, listening on :1801) rather than defining its own vhost.
  # Aliased to the live render in webDir, not a Nix store path -- see
  # configSync above, which is what actually writes it.
  services.nginx.virtualHosts."games-site".locations."/space-engineers/".alias = "${webDir}/";
}
