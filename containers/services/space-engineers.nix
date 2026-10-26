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
#
# Ports: UDP 27016 (game) and UDP 8766 (Steam) are opened on the LAN firewall
# and the container shares the host network stack, so the server is reachable
# at spacedock:27016 on the LAN. Reaching it from the internet still needs a
# UDP 27016 forward on the router.
#
# Changing settings: edit instances/<name>/SpaceEngineers-Dedicated.cfg on the
# host and `systemctl restart podman-space-engineers`. The file is seeded from
# the template below only when it does not exist, so after the first start the
# copy on disk is the source of truth (delete it to re-seed). <LoadWorld> and
# <Plugins> are rewritten by the entrypoint on every start.
#
# Admins: put Steam ID64s in <Administrators> as <string>7656119...</string>.
#
# Stop/restart is graceful: the entrypoint turns SIGTERM into a Ctrl+C event
# for the server, which saves and exits (verified), and the unit waits up to
# 3 minutes for it. A nightly timer
# restarts the service, which is also how game updates are picked up.
{
  lib,
  pkgs,
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
  gamePort = 27016;
  steamPort = 8766;
  instanceName = "spacedock";
  stateDir = "/var/lib/space-engineers";
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

  # Seed config. <SessionSettings> mirrors the <Settings> block of Keen's "Star
  # System" scenario (Content/CustomWorlds/Star System/Sandbox.sbc, game
  # 01_210), with OnlineMode/MaxPlayers overridden; the config's settings are
  # applied to the world on every start, and anything left out would fall back
  # to engine defaults (e.g. ProceduralDensity 0 = no asteroids).
  defaultConfig = pkgs.writeText "SpaceEngineers-Dedicated.cfg" ''
    <?xml version="1.0"?>
    <MyConfigDedicated xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <SessionSettings>
        <GameMode>Survival</GameMode>
        <InventorySizeMultiplier>3</InventorySizeMultiplier>
        <AssemblerSpeedMultiplier>3</AssemblerSpeedMultiplier>
        <AssemblerEfficiencyMultiplier>3</AssemblerEfficiencyMultiplier>
        <RefinerySpeedMultiplier>3</RefinerySpeedMultiplier>
        <OnlineMode>PUBLIC</OnlineMode>
        <MaxPlayers>${toString maxPlayers}</MaxPlayers>
        <MaxFloatingObjects>100</MaxFloatingObjects>
        <MaxBackupSaves>5</MaxBackupSaves>
        <MaxGridSize>0</MaxGridSize>
        <MaxBlocksPerPlayer>0</MaxBlocksPerPlayer>
        <TotalPCU>100000</TotalPCU>
        <MaxFactionsCount>0</MaxFactionsCount>
        <BlockLimitsEnabled>GLOBALLY</BlockLimitsEnabled>
        <EnableRemoteBlockRemoval>true</EnableRemoteBlockRemoval>
        <EnvironmentHostility>NORMAL</EnvironmentHostility>
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
        <WelderSpeedMultiplier>2</WelderSpeedMultiplier>
        <GrinderSpeedMultiplier>2</GrinderSpeedMultiplier>
        <RealisticSound>false</RealisticSound>
        <HackSpeedMultiplier>0.33</HackSpeedMultiplier>
        <PermanentDeath>false</PermanentDeath>
        <AutoSaveInMinutes>5</AutoSaveInMinutes>
        <SpawnShipTimeMultiplier>0</SpawnShipTimeMultiplier>
        <ProceduralDensity>0.35</ProceduralDensity>
        <RandomizeSeed>true</RandomizeSeed>
        <ProceduralSeed>0</ProceduralSeed>
        <DestructibleBlocks>true</DestructibleBlocks>
        <EnableIngameScripts>false</EnableIngameScripts>
        <ViewDistance>15000</ViewDistance>
        <FloraDensity>20</FloraDensity>
        <EnableToolShake>false</EnableToolShake>
        <EnableOxygen>true</EnableOxygen>
        <EnableResearch>true</EnableResearch>
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
        <EnableEconomy>true</EnableEconomy>
        <DepositsCountCoefficient>1</DepositsCountCoefficient>
        <DepositSizeDenominator>60</DepositSizeDenominator>
        <HarvestRatioMultiplier>0.8</HarvestRatioMultiplier>
        <TradeFactionsCount>10</TradeFactionsCount>
        <ScrapEnabled>false</ScrapEnabled>
        <EnableRadiation>true</EnableRadiation>
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
      <Administrators />
      <Banned />
      <GroupID>0</GroupID>
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
    ];

    services.podman-space-engineers.serviceConfig = {
      # The server exits cleanly on its own restarts/updates; always come back.
      Restart = lib.mkForce "always";
      RestartSec = "30s";
      TimeoutStopSec = lib.mkForce 180;
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
  };

  networking.firewall = {
    enable = true;
    allowedUDPPorts = [
      gamePort
      steamPort
    ];
  };
}
