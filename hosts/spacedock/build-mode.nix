# Build mode: spacedock stops its game servers by itself while you compile.
#
# Spacedock has ~15 GiB and both games want a lot of it: the Create Minecraft
# server runs a 6 GB JVM heap (containers/services/minecraft-create.nix) and
# Space Engineers is allowed up to 10 GB (containers/services/space-engineers.nix).
# A large build on top of that (the rr crate, a kernel) runs the box out of
# memory. Neither server hands memory back on its own, so the only way to get
# all of it is to stop them for the length of the build.
#
# Automatic. A small watcher (`build-mode-watch.service`) looks at nix-daemon
# every few seconds. Every Nix build on this box runs inside the daemon's
# cgroup, whatever started it (`just build`, `just rebuild`, a bare
# `nix build`), so nothing has to be wrapped. It pauses the games when, for
# two checks running:
#
#   - a `nix` client is running in a login session (you, over ssh or at the
#     console), and
#   - the daemon's builds hold `pauseAtGiB` or more of their own memory, or
#     any real build is running while the box is under `lowAvailableGiB`
#     available.
#
# The login-session test is deliberate. The nightly cache builder, the
# roll-flow watcher and the Actions runners build through this daemon too,
# and they are meant to yield to a live game (github-runner.nix, the
# binary-cache module), not throw the players off. Small builds don't trip it
# either: a rebuild that only writes a few store paths leaves the games alone.
#
# The games come back once your builds have been idle for `resumeAfterMin`
# minutes, long enough to ride over the gaps between the steps of one `just`
# recipe. A `nixos-rebuild switch` brings them back sooner on its own:
# activation starts multi-user.target, which starts any wanted unit that is
# stopped. That is fine (the compile is done by then), and it means a pause
# can never outlive the next rebuild.
#
# Stop, not freeze. `systemctl freeze` would keep every page resident, players
# would time out against a hung server anyway, and both games jump their
# clocks on thaw. A stop is clean: both images save the world on SIGTERM
# (verified, see the two files above), and Minecraft players get a line in
# chat first.
#
# By hand, for builds outside the daemon (a cargo build in a dev shell):
#   build-mode status                # paused or not, why, and free memory
#   build-mode pause                 # stop both and hold them stopped
#   build-mode resume                # start what a pause stopped
#   build-mode run -- <command>      # pause, run it, resume (even on Ctrl-C)
#   journalctl -u build-mode-watch   # every automatic pause and resume
#
# A manual pause is held: the watcher never resumes it. State lives in
# /run/build-mode (tmpfs; a reboot forgets it, and the units are autoStart).
# Resume only starts what a pause stopped, so a server you stopped yourself
# stays stopped.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # The two game servers. Unit names follow oci-containers: <backend>-<name>.
  gameContainers = [
    "minecraft-create"
    "space-engineers"
  ];
  inherit (config.virtualisation.oci-containers) backend;
  presentGames = lib.filter (
    name: config.virtualisation.oci-containers.containers ? ${name}
  ) gameContainers;
  gameUnits = map (name: "${backend}-${name}.service") presentGames;
  hasMinecraft = lib.elem "minecraft-create" presentGames;

  # Watcher tuning.
  interval = 10; # seconds between checks
  pauseAtGiB = 2; # builds this big pause the games outright
  lowAvailableGiB = 1; # ...as does any real build once MemAvailable is under this
  idleMiB = 256; # daemon build memory under this counts as no build running
  resumeAfterMin = 3; # idle this long before the games come back

  gib = n: n * 1024 * 1024 * 1024;
  mib = n: n * 1024 * 1024;

  buildMode = pkgs.writeShellApplication {
    name = "build-mode";
    runtimeInputs = with pkgs; [
      coreutils
      findutils
      gawk
      procps
      systemd
      config.virtualisation.podman.package
    ];
    text = ''
      units=(${lib.escapeShellArgs gameUnits})
      state_dir=/run/build-mode
      state="$state_dir/paused-units" # units a pause stopped
      held="$state_dir/held"          # present: paused by hand, never auto-resumed
      daemon_cg=/sys/fs/cgroup/system.slice/nix-daemon.service

      interval=${toString interval}
      pause_at=${toString (gib pauseAtGiB)}
      low_avail=${toString (gib lowAvailableGiB)}
      idle_at=${toString (mib idleMiB)}
      resume_after=${toString (resumeAfterMin * 60)}

      # The CLI runs as gig; only systemctl, podman and /run need root.
      as_root() {
        if [ "$(id -u)" -eq 0 ]; then "$@"; else sudo "$@"; fi
      }

      mem() { free -h | awk 'NR==2 {print "  memory: " $3 " used, " $7 " available"}'; }

      running_games() {
        local u
        for u in "''${units[@]}"; do
          if systemctl is-active --quiet "$u"; then echo "$u"; fi
        done
      }

      # The builds' own memory: anonymous pages in nix-daemon's cgroup (and
      # its children). Not memory.current, which also counts the page cache a
      # build leaves behind and would never fall back to idle.
      daemon_anon() {
        awk '$1 == "anon" {print $2; found = 1} END {if (!found) print 0}' \
          "$daemon_cg/memory.stat" 2> /dev/null || echo 0
      }

      available() { awk '$1 == "MemAvailable:" {print $2 * 1024}' /proc/meminfo; }

      # A nix client in a login session: someone at the box asked for this.
      session_build() {
        local pid comm
        while IFS= read -r pid; do
          comm=$(cat "/proc/$pid/comm" 2> /dev/null) || continue
          case "$comm" in
            nix | nix-build | nix-store | nixos-rebuild*) return 0 ;;
          esac
        done < <(find /sys/fs/cgroup/user.slice -name cgroup.procs -exec cat {} + 2> /dev/null)
        return 1
      }

      warn_players() {
        ${lib.optionalString hasMinecraft ''
          as_root timeout 10 podman exec minecraft-create rcon-cli \
            say "Spacedock needs this server's memory for a build. Saving and stopping now; back in a few minutes." \
            > /dev/null 2>&1 || true
        ''}
        :
      }

      # pause <manual|auto>
      pause() {
        local mode="$1" running
        mapfile -t running < <(running_games)
        as_root mkdir -p "$state_dir"
        if [ "$mode" = manual ]; then as_root touch "$held"; fi
        if [ "''${#running[@]}" -eq 0 ]; then
          if [ -f "$state" ]; then
            echo "build-mode: already paused"
          else
            echo "build-mode: no game server was running"
          fi
          return 0
        fi
        # Add to anything an earlier pause recorded, so pausing twice never
        # forgets a server the first pause stopped.
        {
          if [ -f "$state" ]; then cat "$state"; fi
          printf '%s\n' "''${running[@]}"
        } | sort -u | as_root tee "$state.new" > /dev/null
        as_root mv "$state.new" "$state"
        echo "build-mode ($mode): stopping ''${running[*]} (each saves first, up to 3 min)"
        mem
        warn_players
        # One call, so both stop (and save) in parallel.
        as_root systemctl stop "''${running[@]}"
        echo "build-mode: game servers stopped"
        mem
      }

      resume() {
        if [ ! -f "$state" ]; then
          as_root rm -f "$held"
          echo "build-mode: not paused, nothing to resume"
          return 0
        fi
        local to_start=() u
        while IFS= read -r u; do
          [ -n "$u" ] && to_start+=("$u")
        done < "$state"
        if [ "''${#to_start[@]}" -gt 0 ]; then
          # --no-block: queue the starts and return at once. Space Engineers
          # runs a SteamCMD update on every start, and a second Ctrl-C must
          # not be able to cut the restore short.
          as_root systemctl start --no-block "''${to_start[@]}"
          echo "build-mode: starting ''${to_start[*]}"
        fi
        as_root rm -f "$state" "$held"
      }

      status() {
        if [ -f "$state" ]; then
          local why=automatic
          if [ -f "$held" ]; then why="by hand, held until 'build-mode resume'"; fi
          echo "build-mode: PAUSED, $why ($(tr '\n' ' ' < "$state"))"
        elif [ -f "$held" ]; then
          echo "build-mode: held by hand (no game server was running)"
        else
          echo "build-mode: off"
        fi
        local u
        for u in "''${units[@]}"; do
          echo "  $u: $(systemctl is-active "$u" || true)"
        done
        echo "  nix builds: $(($(daemon_anon) / 1048576)) MiB"
        mem
      }

      run() {
        [ "''${1:-}" = "--" ] && shift
        if [ "$#" -eq 0 ]; then
          echo "usage: build-mode run -- <command> [args...]" >&2
          exit 2
        fi
        # If something else already paused, leave the resume to it.
        if [ ! -f "$state" ] && [ ! -f "$held" ]; then
          trap 'trap - EXIT INT TERM HUP; resume' EXIT INT TERM HUP
        fi
        pause manual
        local rc=0
        "$@" || rc=$?
        exit "$rc"
      }

      # The service: pause while your build needs the room, resume after.
      watch() {
        local hot=0 idle=0 anon avail busy
        echo "build-mode-watch: watching ''${units[*]}"
        while sleep "$interval"; do
          anon=$(daemon_anon)
          avail=$(available)
          busy=0
          if [ "$anon" -ge "$idle_at" ] && session_build; then busy=1; fi

          if [ "$busy" -eq 1 ] && { [ "$anon" -ge "$pause_at" ] || [ "$avail" -lt "$low_avail" ]; }; then
            hot=$((hot + 1))
          else
            hot=0
          fi
          if [ "$busy" -eq 1 ]; then idle=0; else idle=$((idle + interval)); fi

          if [ "$hot" -ge 2 ] && [ -n "$(running_games)" ]; then
            echo "build-mode-watch: builds at $((anon / 1048576)) MiB, $((avail / 1048576)) MiB available; pausing"
            pause auto || echo "build-mode-watch: pause failed"
          elif [ -f "$state" ] && [ ! -f "$held" ] && [ "$idle" -ge "$resume_after" ]; then
            echo "build-mode-watch: builds idle for $((idle / 60)) min; resuming"
            resume || echo "build-mode-watch: resume failed"
          fi
        done
      }

      cmd="''${1:-status}"
      shift || true
      case "$cmd" in
        pause) pause manual ;;
        resume) resume ;;
        status) status ;;
        run) run "$@" ;;
        watch) watch ;;
        *)
          echo "usage: build-mode {status|pause|resume|run -- <command>}" >&2
          exit 2
          ;;
      esac
    '';
  };
in
{
  environment.systemPackages = [ buildMode ];

  systemd.services.build-mode-watch = {
    description = "Stop the game servers while a big Nix build of yours runs";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${buildMode}/bin/build-mode watch";
      Restart = "always";
      RestartSec = "10s";
    };
  };
}
