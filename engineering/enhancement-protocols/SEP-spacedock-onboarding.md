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

- `services/pihole.nix` (+ `pihole-config.nix`) — **enabled**; a working Pi-hole
  container so spacedock has a container running out of the box. (nebula-sync
  replica left disabled — environment-specific + carries a token.)
- `services/tdarr-node.nix` — disabled (needs CIFS mounts + samba creds).
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

- [ ] Regenerate `hosts/spacedock/hardware-configuration.nix` on the box.
- [ ] Provision the spacedock host sops age key + `~/nix-secrets` entries +
      `just rekey`.
- [ ] `just build spacedock`, then switch (Pi-hole comes up as an
      oci-container).
- [x] Flip spacedock active in `.roll-flow.toml` on the roll.

## Downstream

Once always-on, spacedock can host the Hydra build worker (gigpkgs#17).
