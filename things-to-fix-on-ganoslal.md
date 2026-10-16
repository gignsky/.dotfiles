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
   4.a. ROOT CAUSE FOUND (2026-10-16) — the client streams over the WAN instead
        of the LAN. This supersedes the earlier `plex-normal-quality` theory,
        which was wrong.
        Evidence: the client's only connection to "Maxwell's Media" is
        `wss://24-211-162-59.<hash>.plex.direct:32400` — 24.211.162.59 is this
        site's PUBLIC IP (confirmed against api.ipify.org). The string
        `192-168-51-3` appears **0 times in every Plex client log**, and the only
        connection it ever tests is `[Loopback] at http://127.0.0.1:32400`
        (which fails — there is no local PMS). So every byte of video leaves the
        network and hairpins back, bounded by upload bandwidth, while the server
        sits 2 ms away on the same /24.
        ganoslal is 192.168.51.50/24, server is 192.168.51.3 — same subnet, one
        hop. `http://192.168.51.3:32400/identity` answers HTTP 200 in 0.002 s.
        Why: the server never advertises its LAN address. Plex GDM discovery
        returns nothing (no reply even to a unicast probe of
        192.168.51.3:32414), and plex.tv is handing the client only the WAN URL
        plus a phantom "Loopback" entry.
        PROPER FIX (server-side, 192.168.51.3 — not managed by this repo):
        PMS Settings > Network > enable local discovery (GDM), and make sure
        "Custom server access URLs" is either empty or includes
        `https://192-168-51-3.<hash>.plex.direct:32400`. When that setting lists
        only a WAN URL, Plex advertises only that.
        VERIFIED CLIENT-SIDE WORKAROUND (ganoslal, in-repo): pin the WAN
        plex.direct hostname to the LAN IP, which keeps the hostname the client
        expects so Plex's wildcard cert still validates:
          curl --resolve 24-211-162-59.<hash>.plex.direct:32400:192.168.51.3 ...
          -> HTTP 200, TLS verify ok, 0.014 s, connected to 192.168.51.3
        Caveat: the hostname embeds the WAN IP, so an ISP address change makes
        the entry stale and silently returns to the slow path. Scope it to
        ganoslal only — never merlin, which leaves the LAN.
        Not measured: actual stream throughput over each path (needs a Plex
        token; extraction was deliberately not pursued).
   4.b. SEPARATE latent DNS bug found while diagnosing the above.
        /etc/resolv.conf carries `search gignsky.com`, and `*.gignsky.com` has a
        wildcard AAAA. Any name whose AAAA lookup fails therefore falls through
        to the search domain and resolves to 2603:6080:ca3e:6907:...:94b0
        instead of failing. Observed directly: `getent hosts
        192-168-51-3.<hash>.plex.direct` returned
        `...plex.direct.gignsky.com` -> that IPv6 address, while the same name
        WITH a trailing dot correctly returned 192.168.51.3. Any IPv6-preferring
        client (Qt/Chromium, i.e. Plex) can be sent to the wrong host by this.
        Worth fixing regardless of Plex; see hosts/common/optional/dns.nix.
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
