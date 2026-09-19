# SEP: Onboard spacedock as a full fleet host

**Status:** in-progress **Branches:**
`claude/dotfiles-spacedock-onboarding-rix2kz` (dotfiles feature) →
`roll/20-0721-spacedock-onboarding` (roll) ;
`claude/dotfiles-spacedock-onboarding-rix2kz` (gigpkgs) **Tracks:** dotfiles#14,
gigpkgs#14, gigpkgs#17

## Summary

Fold the host previously managed by the standalone
[`GeeM-Enterprises/dot-spacedock`](https://github.com/GeeM-Enterprises/dot-spacedock)
flake into the main fleet as a first-class `nixosConfigurations.spacedock`, and
run a container on it via a reusable gigpkgs container engine.

## Architecture

### Container engine (gigpkgs)

`gigpkgs.nixosModules.containers` (gigpkgs PR #20) — the reusable engine:
`gigpkgs.containers.{enable, backend, adhoc.enable, services}`. Sets up the OCI
runtime (podman default) and passes `services` through to
`virtualisation.oci-containers.containers`. Because the fleet's `nixpkgs` input
**is** the gigos gigpkgs channel, the module is consumed as
`inputs.nixpkgs.nixosModules.containers` (injected in `flake.nix`).

### Host (dotfiles)

`hosts/spacedock/{default.nix,hardware-configuration.nix}` — legacy-BIOS GRUB on
`/dev/sda`, fleet core + gig user + the container engine (podman, adhoc on).
`stateVersion = "25.05"` (original install — do not bump). Built from the fleet
`nixpkgs` (`nixpkgs.lib.nixosSystem`), which already points at
`github:gignsky/gigpkgs/gigos-2605`, so spacedock rides gigos with no per-host
input. Hardware carried from dot-spacedock — **regenerate on the box** before
switch.

### Container payloads (dotfiles, `containers/`)

- `services/pihole.nix` (+ `pihole-config.nix`) — **enabled**; Pi-hole DNS replica
  plus nebula-sync against the master on memory-alpha. See "Pi-hole slave
  reactivation" below.
- `services/tdarr-node.nix` — enabled.
- `services/avec-moi-app.nix` — enabled.
- `buzz/`, `mini/` — disabled adhoc nixos-generators images + runners.

## nixpkgs base — note

Earlier this SEP wired a dedicated `gigos-stable` input scoped to spacedock.
That is now **obsolete**: `main` swapped the whole fleet's `nixpkgs` to
`github:gignsky/gigpkgs/gigos-2605` and dropped the standalone `gigpkgs` input
(`inputs.gigpkgs.*` → `inputs.nixpkgs.*`). Spacedock therefore just uses the
fleet `nixpkgs`; no scoped input needed.

## Roll-flow

Per roll-flow, the feature branch merges into a roll, not `main`:

- `roll/20-0721-spacedock-onboarding` is the roll (based off `main`); the
  dotfiles PR merges the feature branch into it.
- Host activity lives in `.roll-flow.toml`:
  `roll/19-0721-apply-roll-flow-toml-basic` sets **wsl-only** active; spacedock
  is flipped online on the roll after `rf integrate roll/19` pulls the base
  config in as a dependency.

## Dependency chain (order to merge)

1. **gigpkgs#20** → gigpkgs `master` (the container engine).
2. gigpkgs regenerates the **`gigos-2605`** channel branch from master so
   `nixosModules.containers` is present on it.
3. dotfiles relock (`nix flake lock --update-input nixpkgs`) so
   `inputs.nixpkgs.nixosModules.containers` resolves.
4. Roll integrates + graduates per roll-flow.

## Remaining manual steps before switch

- [x] Regenerate `hosts/spacedock/hardware-configuration.nix` on the box.
- [x] Provision the spacedock host sops age key + `~/nix-secrets` entries +
      `just rekey`.
- [x] Run dry-activate
- [x] `just build spacedock`, then switch (Pi-hole comes up as an
      oci-container).
- [x] Flip spacedock active in `.roll-flow.toml` on the roll.

## Downstream

Once always-on, spacedock can host the Hydra build worker (gigpkgs#17).

## Pi-hole slave reactivation (roll/114-0918-pihole-slave-activate)

The payload shipped with onboarding but was parked: the import was commented out
and the nebula-sync replica was commented out, because both carried plaintext
secrets. This roll turns it on properly. Spacedock is the **slave**; the master is
memory-alpha (the TrueNAS box, `192.168.51.3`, web UI `:20720`) and is not managed
by this repo.

### Decisions, and why

**Selective sync, not `FULL_SYNC`.** Two independent reasons, both verified
against nebula-sync's source rather than its docs:

1. Any Pi-hole setting supplied via an `FTLCONF_*` env var becomes **read-only** —
   the API answers `400 bad_request` with `hint: dns.listeningMode` on any attempt
   to change it. `newFullSyncConfigSettings()` in `internal/sync/full.go` sets
   `DNS: NewConfigSetting(true, nil, nil)` — enabled with a *nil filter* — so a
   full sync PATCHes the entire `dns` object including `listeningMode`, exhausts
   `AttemptsPatchConfig = 5`, and aborts the whole run. We pin
   `FTLCONF_dns_listeningMode = "all"` on purpose (a container behind podman NAT
   must listen broadly, and read-only means no sync can leave the replica deaf),
   so `SYNC_CONFIG_DNS_EXCLUDE=listeningMode` is mandatory. The exclude key is
   scoped to the `dns` sub-object, hence `listeningMode`, **not**
   `dns.listeningMode`.
2. A full sync also clones the `dhcp` section, `dhcp.active` included. Cloning
   that onto a standby would create a second DHCP server on the LAN. Hence
   `SYNC_CONFIG_DHCP=false`.

`FULL_SYNC=true` is definitionally "every `SYNC_*` on, `Webserver`/`Files` off",
so selective sync is not a downgrade — it is the same sync minus two carve-outs.

**`FTLCONF_webserver_api_password` is safe to pin.** `RawConfigSettings.Webserver`
and `.Files` are both `ignored:"true"` in `internal/config/config.go`, and
`newFullSyncConfigSettings()` disables `Webserver`. The webserver section is never
PATCHed in either mode, so sync cannot fight the pinned password.

**nebula-sync is a systemd oneshot + timer, not an oci-container.** It is a batch
job. `Run()` in `internal/service/service.go` syncs *immediately* and returns the
error if that first sync fails — cron is never installed. As a long-running
container (`Restart=on-failure`, `sdnotify=conmon`, so "ready" means "the
container started", not "FTL is listening") a cold boot races FTL opening the
72 MB `gravity.db` and lands in a restart loop until systemd's start limit parks
the unit. The timer gives boot slack (`OnBootSec=10min`), `Persistent=true` catches
runs missed while the box was off, and `systemctl start nebula-sync` is the
on-demand sync (`just pihole-sync-now`). A `preStart` gate polls the replica's API
until it answers before the sync runs.

**Password rotation was a prerequisite, not a nicety.** The old dot-spacedock
config committed the API password in plaintext to a public repo, on `main` *and*
the `container/pihole/updates` branch. It is now `pihole/api-password` in
`~/nix-secrets/secrets.yaml`, shared by master and replica, rendered into two
`sops.templates` and injected with `environmentFiles`. Rotating requires changing
it on the master too — `PRIMARY` auth breaks the instant one side moves.

### Caveats on record

- `sops.useSystemdActivation` is `false` here (no sysusers/userborn), so sops runs
  as the `setupSecrets` activation script and `restartUnits` goes through
  `/run/nixos/activation-restart-list`. `switch-to-configuration` warns this is
  **deprecated and removed in NixOS 26.11** — revisit then.
- Scope is a sync-only hot standby. Publishing `53:53` does make spacedock
  *reachable* as a resolver at `192.168.51.2:53`, but nothing advertises it and no
  host's resolver points here. `hosts/common/optional/dns.nix` (unmerged on
  `roll/111-0916-ganoslal-working-again`) still pins ganoslal and merlin to the
  router after the master wedged in Sept 2026. Repointing the fleet is a separate
  follow-up; when it happens, always leave a second nameserver entry so one wedged
  resolver cannot stall a host.
- `env-file` syntax is silently unforgiving: podman splits on the first `=` and
  strips no quotes, and a line with no `=` is read as "inherit from host" and
  *deletes* the variable. The sops templates must never gain spaces around `=` or
  trailing whitespace. The password itself must contain no comma (`REPLICAS` splits
  on `,` before `|`) and no newline — store it as a plain YAML scalar, not a `|`
  block scalar.
- `internal/sync/sync.go: authenticate()` calls `Primary.PostAuth()` with **no**
  retry wrapper (only replicas retry), so a momentary blip on the master fails the
  whole run. The 4 h timer is the retry.
- `/var/lib/pihole/etc-pihole` carries the Dec 2025 deployment's DBs at the same
  v6 version as the pinned image, kept deliberately (no schema migration, gravity
  already populated). The tmpfiles rules are `- - - -` so they create the dirs but
  never chown the existing ~170 MB tree.
