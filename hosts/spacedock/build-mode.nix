# Build mode: stop spacedock's game servers so a big compile gets their RAM.
#
# Spacedock has ~15 GiB and both games want a lot of it: the Create Minecraft
# server runs a 6 GB JVM heap (containers/services/minecraft-create.nix) and
# Space Engineers is allowed up to 10 GB (containers/services/space-engineers.nix).
# A large build on top of that (the rr crate, a kernel) runs the box out of
# memory. Neither server hands memory back on its own, so the only way to get
# all of it is to stop them for the length of the build.
#
# Stop, not freeze. `systemctl freeze` would keep every page resident (zram
# could compress some of it, but that is all), connected players would time
# out against a hung server anyway, and both games jump their clocks on thaw.
# A stop is clean: both images save the world on SIGTERM (verified, see the
# two files above) and their units already allow up to 3 minutes for it.
#
# Usage (the `just` recipes are in the justfile; they add the sudo prompt up
# front so it does not appear halfway through a build):
#
#   just build-mode rebuild        # any just recipe, with the games paused
#   just build-mode build .#foo    #   (restored after, even on failure/Ctrl-C)
#   just pause-games               # stop both and remember which were running
#   just resume-games              # start the ones pause stopped
#   build-mode status              # paused or not, and free memory
#   build-mode run -- <command>    # wrap anything else, e.g. a cargo build
#
# Pause records what it stopped in /run/build-mode (tmpfs, so a reboot forgets
# it, and the units are autoStart anyway). Resume only starts what pause
# stopped, so a server you had stopped yourself stays stopped. `run` restores
# only if it was the one that paused, so it nests inside a manual pause.
#
# Rebuilds: switch-to-configuration starts multi-user.target, which brings back
# any wanted unit that is stopped. So a rebuild during a pause starts the games
# again at activation, after the compile is done; that is deliberate, so a
# forgotten pause can never outlive the next rebuild. Resume then finds them
# running and does nothing. The nightly Space Engineers restart uses
# try-restart, which leaves a stopped server alone.
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
  gameUnits = map (name: "${backend}-${name}.service") (
    lib.filter (name: config.virtualisation.oci-containers.containers ? ${name}) gameContainers
  );

  buildMode = pkgs.writeShellApplication {
    name = "build-mode";
    runtimeInputs = with pkgs; [
      coreutils
      gawk
      procps
      systemd
    ];
    text = ''
      units=(${lib.escapeShellArgs gameUnits})
      state_dir=/run/build-mode
      state="$state_dir/paused-units"

      # Run as gig from the justfile; only systemctl and /run need root.
      as_root() {
        if [ "$(id -u)" -eq 0 ]; then "$@"; else sudo "$@"; fi
      }

      mem() { free -h | awk 'NR==2 {print "  memory: " $3 " used, " $7 " available"}'; }

      pause() {
        local running=() u
        for u in "''${units[@]}"; do
          systemctl is-active --quiet "$u" && running+=("$u")
        done
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
        as_root mkdir -p "$state_dir"
        {
          [ -f "$state" ] && cat "$state"
          printf '%s\n' "''${running[@]}"
        } | sort -u | as_root tee "$state.new" > /dev/null
        as_root mv "$state.new" "$state"
        echo "build-mode: stopping ''${running[*]} (each saves first, up to 3 min)"
        mem
        # One call, so both stop (and save) in parallel.
        as_root systemctl stop "''${running[@]}"
        echo "build-mode: game servers stopped"
        mem
      }

      resume() {
        if [ ! -f "$state" ]; then
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
        as_root rm -f "$state"
      }

      status() {
        if [ -f "$state" ]; then
          echo "build-mode: PAUSED ($(tr '\n' ' ' < "$state"))"
        else
          echo "build-mode: off"
        fi
        local u
        for u in "''${units[@]}"; do
          echo "  $u: $(systemctl is-active "$u" || true)"
        done
        mem
      }

      run() {
        [ "''${1:-}" = "--" ] && shift
        if [ "$#" -eq 0 ]; then
          echo "usage: build-mode run -- <command> [args...]" >&2
          exit 2
        fi
        # If something else already paused, leave the resume to it.
        local owner=1
        [ -f "$state" ] && owner=0
        if [ "$owner" -eq 1 ]; then
          trap 'trap - EXIT INT TERM HUP; resume' EXIT INT TERM HUP
        fi
        pause
        local rc=0
        "$@" || rc=$?
        exit "$rc"
      }

      cmd="''${1:-status}"
      shift || true
      case "$cmd" in
        pause) pause ;;
        resume) resume ;;
        status) status ;;
        run) run "$@" ;;
        *)
          echo "usage: build-mode {pause|resume|status|run -- <command>}" >&2
          exit 2
          ;;
      esac
    '';
  };
in
{
  environment.systemPackages = [ buildMode ];
}
