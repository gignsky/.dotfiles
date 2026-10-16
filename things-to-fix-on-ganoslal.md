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
   4.a. ROOT CAUSE CONFIRMED (2026-10-16). The Plex server advertises "local"
        addresses that no client on the real LAN can reach, so every client
        falls back to the public IP and streams out to the internet and back.
        What the server publishes to plex.tv (from the client logs), and whether
        ganoslal (192.168.51.50/24, GUA IPv6 only) can use it:
          172-16-23-2.<hash>.plex.direct        172.16.23.2    UNREACHABLE
          fdd0-...-0002.<hash>.plex.direct      fdd0::13::2    UNREACHABLE
          24-211-162-59.<hash>.plex.direct      24.211.162.59  works = WAN
          https://plex.gignsky.com (custom)     24.211.162.59  works = WAN
          https://www.plex.gignsky.com (custom) 24.211.162.59  works = WAN
        So PMS runs on a container/VM network (172.16.23.0/24 + fdd0:0:0:13::/64)
        and does not know it is reachable at 192.168.51.3. `192-168-51-3` appears
        0 times in every client log. This also explains why GDM discovery returns
        nothing, even to a unicast probe — broadcasts do not cross that bridge.
        Meanwhile the LAN path is perfectly healthy and fast:
          http://192.168.51.3:32400/identity          -> 200 in 0.002 s
          https://192-168-51-3.<hash>.plex.direct:32400 -> 200, TLS ok, 0.048 s
        FIX (server-side, one setting, fixes every LAN client at once): append
        the LAN plex.direct URL to Custom server access URLs, so the list reads
          https://plex.gignsky.com,https://www.plex.gignsky.com,https://192-168-51-3.7417054e0444471ba79889c51bd5546e.plex.direct:32400
        TLS validates because the Plex cert is a wildcard for *.<hash>.plex.direct,
        which is why this works on any IP. Better long-term: give the Plex
        container/VM a real LAN address (macvlan or host networking), which also
        restores GDM.
        FALLBACK (ganoslal-only, in-repo, verified): pin the WAN plex.direct
        hostname to the LAN IP via networking.hosts —
          curl --resolve 24-211-162-59.<hash>.plex.direct:32400:192.168.51.3
          -> 200, TLS verify ok, 0.014 s, connected to 192.168.51.3
        Goes stale if the ISP changes the WAN IP, and must never go on merlin,
        which leaves the LAN. Prefer the server-side fix.
        Not measured: per-path stream throughput (needs a Plex token; extraction
        was deliberately not pursued).
   4.b. RED HERRING, retained for the record. /etc/resolv.conf has
        `search gignsky.com` and *.gignsky.com has a wildcard AAAA, so any
        AAAA-failing lookup resolves via the search domain instead of failing
        (`getent hosts <lan>.plex.direct` returned ...plex.direct.gignsky.com,
        while the same name with a trailing dot returned 192.168.51.3).
        Initially suspected of contributing to the Plex fault; it does NOT —
        that IPv6 address is the Plex server itself (its MAC 40:a8:f0:25:94:b0
        matches the EUI-64, and ARP confirms it is 192.168.51.3 on-link). Still
        an oddity worth tidying, but unrelated.
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
