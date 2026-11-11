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
