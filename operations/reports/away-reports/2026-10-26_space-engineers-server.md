# Space Engineers dedicated server on spacedock — handoff

**Date:** 2026-10-26
**Branch:** `roll/142-1026-space-engineers-server`
**Host:** spacedock (i7-6800K, 12 threads, 15 GiB RAM, no swap, 257 GB free)

---

## TL;DR

`containers/services/space-engineers.nix` runs Keen's Windows-only dedicated
server under Wine as a podman service on spacedock. It is wired into
`containers/services/default.nix` and **not yet deployed**: the config builds,
and the container was smoke-tested rootless on spacedock under `~/se-smoke`
(fresh world generated, `Game ready`, graceful stop saved the world, restart
loaded it). Deploy with:

```bash
# on spacedock
cd ~/.dotfiles
git pull            # roll/142
just rebuild
journalctl -fu podman-space-engineers.service
```

First start downloads ~8 GB from Steam and patches the Wine prefix; after
that a start takes about 100 s to `Game ready` (in the instance log) and a
stop about 5 s. A stop during the SteamCMD phase is immediate.
Then connect from the game to `spacedock:27016` (LAN) — it also announces to
Steam's server list as "Spacedock" (OnlineMode PUBLIC, no password, no group
restriction). Internet play needs a UDP 27016 forward on the router.

## What is where

| Path on spacedock | Purpose |
|---|---|
| `/var/lib/space-engineers/game` | SteamCMD install of app 298740 (~8 GB) |
| `/var/lib/space-engineers/instances/spacedock/` | `SpaceEngineers-Dedicated.cfg`, `Saves/Spacedock/`, `SpaceEngineersDedicated_*.log` |
| `/var/lib/space-engineers/plugins` | drop `.dll` plugins here; picked up on restart |
| `/var/lib/space-engineers/steamcmd` | SteamCMD itself |
| `/var/lib/space-engineers/wine` | Wine prefix (seeded from the image, VC++ runtime added) |

Unit: `podman-space-engineers.service` (Restart=always, 3-minute stop timeout).
Timer: `space-engineers-restart.timer` restarts it daily at 05:00 local, which
is also how game updates are applied (SteamCMD runs on every start).

## Changing settings

Edit `/var/lib/space-engineers/instances/spacedock/SpaceEngineers-Dedicated.cfg`
on the host, then `sudo systemctl restart podman-space-engineers`. The file is
only seeded from the Nix template when it does not exist. The template's
`<SessionSettings>` mirror Keen's "Star System" scenario with MaxPlayers 8 and
OnlineMode PUBLIC; the config's session settings are applied to the world on
every start, so this file is the source of truth for game rules. Admins go in
`<Administrators>` as `<string>7656119…</string>` (Steam ID64).

Server/world name, max players, scenario, ports, memory cap and the restart
time are `let` bindings at the top of the Nix file; changing those only affects
a *new* instance's seed config (except ports/memory/timer, which are host-side).

## Things learned the hard way

- **Image choice.** `devidian/spaceengineers:winestaging` is the only Linux SE
  image still rebuilt (2026-09). Its own entrypoint needs an instance created
  with the Windows GUI tool and rewrites `<LoadWorld>` even before a save
  exists, so the payload bind-mounts a Nix-managed entrypoint instead.
- **World generation without Windows.** With `<LoadWorld />` empty and
  `<PremadeCheckpointPath>` pointing at
  `Content/CustomWorlds/<Scenario>` inside the server install, the server
  generates `Saves/<WorldName>/` itself. The entrypoint then locks
  `<LoadWorld>` to the newest save so it never generates twice.
- **Missing VC++ runtime (upstream issue #91).** The image's prefix has no
  `vcruntime140`, so the server exits with "Please install latest C++
  redistributable package for 2015-2019 x64". winetricks' `vcrun2022` aborts
  on its x86 half in this image; running Microsoft's `vc_redist.x64.exe
  /install /quiet /norestart` directly works (17 s). Never `wineserver -w`
  after it — that waits on the .NET native-image service and took 16 minutes.
- **SteamCMD "Missing configuration".** The first `app_update` after a fresh
  SteamCMD reliably fails with that error and the retry succeeds; the
  entrypoint retries three times.
- **Graceful stop.** `taskkill /IM` cannot find the server (no window under
  `-noconsole`). `SIGINT` to the real `SpaceEngineersDedicated.exe` process
  (not the `start.exe` wrapper `wine` spawns) becomes a console Ctrl+C that the
  server handles by saving and exiting in about a second.
- **Session settings override the scenario.** Any `<SessionSettings>` element
  left out of the config falls back to engine defaults, not the scenario's —
  a minimal block gave `ProceduralDensity 0` (no asteroids) and TotalPCU
  600000. The template therefore carries the scenario's full block.
- **Rootless podman dies with the SSH session** on spacedock (no linger for
  gig), which is why the smoke test needed a "keeper" session. Irrelevant for
  the real unit, which is rootful under system systemd.
- **Spacedock has no swap**, hence the `--memory=10g` cap: a runaway server is
  OOM-killed and restarted instead of taking the binary-cache builder down.

## Not done / follow-ups

- Deploy (`just rebuild` on spacedock) and connect once from the game.
- Router port-forward for UDP 27016 if non-LAN players are wanted.
- Password: the config stores a hash+salt that only the Windows GUI tool
  computes; use `<GroupID>` (Steam group) or a Tailscale/LAN-only stance
  instead, or generate the hash with the DS tool on a Windows box.
- Backups: `Saves/` keeps 5 rotating backups (`MaxBackupSaves`), nothing
  off-box yet.
- Smoke-test leftovers were removed from `~/se-smoke` and gig's rootless
  image store on spacedock.
