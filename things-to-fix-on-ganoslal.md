1. Resolution on main monitor is not correct.
   1.a. Resolved — DP-2 is forced to 5120x1440@144. Its EDID-preferred mode is
        1920x1080, so anything that reached for `xrandr --auto` handed the
        ultrawide a 1080p mode. The layout script no longer uses `--auto` for
        DP-2 on any path. See `hosts/ganoslal/nvidia.nix`.
2. Three top monitors are not properly orianted in space above the main monitor.
   2.a. Resolved — same root cause as #1, not a separate bug. On a login where
        one output was not yet present, the old guard fell through to a fallback
        that re-laid *every* output left-to-right with `--auto`, flattening the
        two rows into one. `/tmp/xrandr-init.log` shows this on 2 of 8 logins
        (the 2026-10-15 13:29 entry is the reported state).
        Fixes: the settle/wait now runs at login, not just on resume; the
        verdict comes from one cached `xrandr --query` instead of four separate
        ones; a missing output yields a *partial* apply that leaves the present
        monitors where they are; and a user timer re-verifies every 2 min so a
        panel power-cycle or late GPU probe self-heals.
        Pause it with `touch "$XDG_RUNTIME_DIR/ganoslal-displays.pause"`.
3. Need to figure out what the name of that other desktop manager was that Gabby was using (might be named in 'notes-on-the-go.md') that had infinite scrolling horizontal terminals and windows.
   3.a. Answered — **niri**, a scrollable-tiling Wayland compositor. Recorded in
        `~/local_repos/annex/notes-on-the-go.md` under "bspwm replacement ideas"
        as `- niri (what gabby uses)`. Still open: whether to actually move off
        bspwm, which would retire the whole xrandr layout script above.
4. Plex does not play videos, it buffers endlessly.
5. There is an issue where when a nix build is going on on merlin or ganoslal, then the rest of the system hangs and processes things slowly. This could likely be resolved by reserving how much of the overall system resources may be used by nix if other things are trying to use said resources.
   5.a. Resolved — `hosts/common/optional/nix-build-throttle.nix`, imported by
        ganoslal and merlin only (build servers are deliberately left alone, so
        spacedock's nightly builder and roll-flow watcher keep the whole box).
        Measured cause: nix defaulted to `max-jobs = 12, cores = 0` on a
        6-core/12-thread 5600X — up to 12 jobs each free to use all 12 threads,
        with no memory or I/O limit anywhere.
        Two layers: admission control (`max-jobs = 4`, `cores = 2`,
        `max-substitution-jobs = 8`) bounds work in flight; priority
        (`daemonCPUSchedPolicy = "batch"`, `daemonIOSchedClass = "idle"`,
        plus CPUWeight/IOWeight 20 and MemoryHigh 60% on nix-daemon) decides who
        wins only under contention — an idle machine still gives a build the
        whole box. Verified a build process lands in
        `/system.slice/nix-daemon.service`, the cgroup those weights bind.
        Burst for one big build without rebuilding:
          sudo systemctl set-property --runtime nix-daemon.service CPUWeight=100 IOWeight=100
