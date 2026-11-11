# Space Engineers: shared website + password gate — handoff

**Date:** 2026-11-11
**Branch:** `roll/142-1026-space-engineers-server`
**Builds on:** `2026-10-26_space-engineers-server.md` (the server itself, smoke-tested,
not yet deployed)

---

## TL;DR

This session resolved the two open design questions from the 2026-10-26 report
and added a public-facing website:

- **Exposure:** public internet, via a router port-forward (not Tailscale/LAN-only).
- **Access:** locked to NISC members with a shared password, shown on the website
  — not left fully open.
- **Website:** `containers/services/minecraft-create.nix`'s existing
  `games.gignsky.com` site is now a shared hub. `containers/services/games-site.nix`
  owns the hub page and the single nginx vhost (`games-site`, :1801); Minecraft's
  page moved to `/minecraft/` and Space Engineers got a new page at
  `/space-engineers/`, each contributed by its own service file via
  `services.nginx.virtualHosts."games-site".locations`.

Still **not deployed** — this is still a from-source review/design session, not a
run on spacedock itself.

## What changed this session

1. **`containers/services/games-site.nix`** (new) — the shared vhost + hub page
   linking to `/minecraft/` and `/space-engineers/`. Opens TCP 1801 (LAN-facing
   only; unchanged posture from before, just moved here).
2. **`containers/services/minecraft-create.nix`** — dropped its own nginx
   `enable`/vhost/firewall-port ownership (now games-site.nix's job), kept its
   `/mods.zip`, `/create-server.zip`, `/pack/` locations as-is (unchanged URLs,
   so already-imported Prism instances don't break), and moved its main page to
   `/minecraft/`.
3. **`containers/services/space-engineers.nix`** — added a website page and a
   password gate:
   - `<ServerPasswordHash />`/`<ServerPasswordSalt />` placeholders added to the
     seed config (new elements; the schema already supports them per Keen's
     `IMyConfigDedicated` API, just unused here before).
   - `space-engineers-password-configure`: a host-side script (Python3, via
     `ExecStartPre` on `podman-space-engineers.service`) that reads the
     `space-engineers/password` sops secret, computes
     **PBKDF2-HMAC-SHA1, 10000 iterations, 16-byte salt, 20-byte key, base64**
     for both values, patches them into the live cfg, and renders the website's
     password display from the same plaintext — so the secret never touches the
     Nix store, and rotating it is just "change the sops secret, `systemctl
     restart podman-space-engineers`".
   - **This hashing scheme is community-reverse-engineered, not official.**
     Keen's own Windows "Dedicated Server" GUI tool is the only thing that
     officially computes these fields; there is no documented server-side spec.
     Two independent community projects (`privatesourcetech/se-shipyard`,
     `Stark-52/se-server-macos`) agree on the parameters above, but
     se-shipyard's own README says it's "not yet verified against a real
     client connect." **Verify this by actually joining with the password
     after the first deploy** (see Not done, below). I tested the script's own
     logic end-to-end (seeding, idempotent hash on an unchanged password,
     correct hash change on rotation, correct webpage substitution) — just not
     against a real Space Engineers client, which I have no way to do from
     here.
   - If the hash turns out to be wrong: run Keen's free "Space Engineers
     Dedicated Server" tool (Steam Tools) once on a Windows box, enter the
     password there, and paste its two generated lines directly into the live
     `instances/spacedock/SpaceEngineers-Dedicated.cfg` by hand — the
     automated script can then be disabled (drop the `ExecStartPre` line) or
     just left alone and overwritten manually after every restart.
   - Server stays `OnlineMode PUBLIC` (still shows up in Steam's server
     browser, per the "public internet" exposure decision) but now requires
     the password to actually join.

## Ports to forward on the router (to spacedock's LAN IP, 192.168.51.2)

| Port | Proto | Purpose | Status |
|---|---|---|---|
| 25565 | TCP | Minecraft | Done 2026-10-26 |
| 27016 | UDP | Space Engineers game | **Not done** |
| 8766 | UDP | Space Engineers Steam query/browser | **Not done** |
| 1801 | TCP | website (games.gignsky.com) | **Do not forward** — stays behind the existing front-nginx-on-memory-alpha proxy, LAN-only |

## Before deploying

Add to `nix-secrets/secrets.yaml` (`just sops`), if not already present:

```yaml
space-engineers:
  password: <the shared passphrase for NISC members>
```

Pick something easy to read off a phone screen and type on a game controller —
it's displayed in plaintext on the website by design.

## Addendum (same day): live status + a 403 fix

After the first deploy, `/space-engineers/` 403'd: its rendered page lived
under `/var/lib/space-engineers/web`, nested inside a `0750 root:root`
directory (intentionally restrictive -- it holds the SteamCMD install etc.),
so nginx's own unprivileged worker couldn't even traverse into it. Fixed by
moving the render target to a separate `/var/lib/space-engineers-web` (0755),
matching the `dataDir`/`webDir` split `minecraft-create.nix` already used.

Also added live Online/Offline status (with player counts) to both pages and
the hub:

- **Minecraft:** a real Server List Ping (wiki.vg) against the published
  game port, every 30s, written to `webDir/status.json`.
- **Space Engineers:** a real Steam A2S_INFO query (the same protocol
  Steam's own server browser uses, challenge-response included) against the
  Steam query port, every 30s, written to `webDir/status.json`.
- A shared `/status.js` (games-site.nix) polls each page's `status.json`
  client-side and renders Online/Offline inline, on the hub too.

Both status-check scripts are tested against hand-rolled fake servers that
speak the real protocol (challenge flow included for A2S) -- not against a
real Minecraft or Space Engineers server, which this session has no way to
run. They're read-only queries against already-open ports, so a wrong parse
just shows "Status unavailable" rather than doing anything harmful; worth a
glance after deploy to confirm the numbers look right once players are on.

## Addendum 2 (same day): research off + settings list

Set `EnableResearch` to `false` (was `true`). A handful of gameplay settings
(game mode, max players, scenario, environment hostility, resource/tool
multipliers, oxygen, research, economy, radiation, asteroid density) are now
named `let` bindings instead of bare XML literals, and the Space Engineers
page renders a settings table straight from those same bindings -- so the
website can't drift from what the cfg actually says. Verified by building
the real `defaultConfig` and `webTemplate` derivations and running the
password-configure script against them end to end (not just a syntax check).

## Addendum 3 (same day): A2S was the wrong protocol, status fixed

After deploy, the website showed the Space Engineers server as offline even
though it was running and joinable -- confirmed by hand on spacedock
(`journalctl -u space-engineers-status-check.service`, and a raw UDP probe
of port 8766) that nothing answers Valve's A2S_INFO query at all. Wrong
assumption, now corrected: Space Engineers is Keen's own VRage engine, not
Source engine, and doesn't implement that wire protocol, even though Steam's
client-side server browser can still list it (by some other internal
mechanism). Keen's documented alternative is the Dedicated Server's Remote
API (`<RemoteApiEnabled>`/`<RemoteApiPort>`, still off), but its HTTP auth is
an undocumented HMAC+timestamp scheme with no official reference -- not
worth guessing at a second time in the same session.

Replaced the whole A2S script with `systemctl is-active --quiet
podman-space-engineers.service`: no player count this way, just
online/offline, but it's an actually-correct signal instead of a
plausible-looking wrong one. `status.js` now renders "Online" with no count
when a status payload omits `players`/`max_players` (Minecraft's SLP-based
check still returns both and is unaffected -- that protocol is real and
core to every Minecraft server, so there's no reason to think it has the
same problem, though it hasn't been confirmed against a live server either).

If real Space Engineers player counts matter later, the Remote API is the
path, but it needs someone to either find Keen's actual auth-signing spec or
test the HMAC scheme against a live server rather than guess at it blind.

## Addendum 4 (same day): rubber-banding for a remote player (Portugal)

Reported: a remote player (high RTT, transatlantic) saw rubber-banding.
Baseline network latency on that path is a real, unfixable floor, but
rubber-banding on top of it usually means the server's simulation tick
intermittently falls behind real-time (sim speed < 1.0) -- the resulting
correction is a bigger snap, and it's most visible to whichever client has
the highest round-trip time, i.e. exactly the remote player.

Spacedock runs several other background/batch workloads alongside the game:
Tdarr transcoding (CIFS-mounted media, VA-API hardware encode but still CPU
overhead for orchestration) and three self-hosted GitHub Actions runners
(gigpkgs, christina-website, kottonmouth) whose jobs include `cargo`/`rustc`/
`gcc` builds and on-demand `nix build`s (the two rolling-deploy units). None
of these had any scheduling priority set, so a CI job or a transcode landing
mid-session competes equally with the live game for CPU -- a plausible and
fixable contributor, as distinct from pure network latency/jitter, which
isn't.

Fix: gave all of them `Nice = 19` + `IOSchedulingClass = "idle"`, the exact
same treatment `modules/nixos/binary-cache/service.nix` already uses for the
nightly binary-cache builder ("Builds are background work; never starve
interactive use"). This only matters under contention -- on an idle box
these jobs still get the whole machine, same as before.

- `containers/services/tdarr-node.nix`: `podman-tdarr-node.service`.
- `hosts/spacedock/github-runner.nix`: all three runner services
  (`serviceOverrides.Nice`/`IOSchedulingClass`), plus both `mkRollingDeploy`-
  generated units (kottonmouth/christina rolling deploys), which run actual
  `nix build`s.
- Also fixed a stale header comment on tdarr-node.nix claiming it was
  disabled/not imported; it is imported and running.

**Deliberately not touched:** spacedock's own `nix-daemon` is NOT throttled
via `nix-build-throttle.nix` (by design -- see that file's header: spacedock
is the fleet's build server, and throttling it would slow the binary cache
for everyone). So a `just rebuild`/`nixos-rebuild switch` on spacedock
itself will still cause a brief CPU spike during the rebuild. That's a
short, one-off event, not the sustained background load this fix targets,
and changing it would conflict with an existing, deliberate design
decision -- flagging it rather than touching it.

**Not fixed by this, and can't be from the server side:** the physical
network path itself (ISP routing, packet loss, jitter on the Portugal leg).
If rubber-banding persists after this deploys, the next diagnostic step is
checking in-game Sim Speed (F11 performance overlay) during a laggy moment:
below 1.00 points back at server-side load (worth also checking `htop` on
spacedock at that moment to see what's actually running); a normal Sim Speed
with still-bad rubber-banding points at the network path itself, which would
need a traceroute/mtr from the remote player's side to narrow down.

## Not done / follow-ups

- Deploy (`just rebuild` on spacedock) — needs to run on spacedock itself.
- Add the sops secret (above) before the first switch, or the build fails
  (`sops.secrets` validation).
- **Verify the password actually works** by joining from a real client once
  deployed. This is the main residual risk from this session's work — see the
  caveat above.
- Router port-forwards for UDP 27016 + UDP 8766.
- Everything else carried over unresolved from 2026-10-26: backups (`Saves/`
  only keeps 5 rotating in-place backups, nothing off-box), and connecting
  once from the game to confirm the base server itself still behaves after a
  real deploy.
