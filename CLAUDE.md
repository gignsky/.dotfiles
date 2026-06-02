# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Shell Environment

All agents operate in a **Nushell** environment by default, NOT bash. Use Nushell conventions:
- `;` instead of `&&` for command chaining
- `out+err>` instead of `2>&1` for error redirection

## Build Commands

```bash
just rebuild              # Rebuild NixOS system (auto-detects host)
just home                 # Rebuild Home Manager
just rebuild-full         # System + Home Manager
just check                # Flake validation (nix flake check --keep-going)
just pre-commit           # Run pre-commit hooks on all files
just build [TARGET]       # Build specific flake target
just test-rebuild         # Dry-run evaluation without applying
just test-home            # Build home-manager without switching
just update               # Update flake.lock + rekey secrets
just gc                   # Garbage collect old nix store entries
```

WSL note: The flake target for WSL must be `wsl` (not the hostname `nixos`). `scripts/get-flake-target.sh` handles this mapping automatically.

## Architecture

### Flake Structure

- **`flake.nix`** — Entry point. Defines `nixosConfigurations` (ganoslal, merlin, wsl) and `homeConfigurations` (gig@{wsl,spacedock,merlin,ganoslal}). Uses nixpkgs stable 26.05 for most hosts; merlin uses nixpkgs-unstable.
- **`vars/`** — Global config values (`configVars`): username, uid/gid, hostname mappings. Passed to all modules as `specialArgs`.
- **`lib/`** — Utility functions (`configLib`): `relativeToRoot`, `scanPaths` (auto-import directories of .nix files), `scanPathsNuShell` (concatenate .nu files for extraConfig).
- **`pkgs/`** — Custom Nix packages. `scripts.nix` wraps shell scripts as proper packages with dependency injection via `makeScriptPackage`.
- **`overlays/`** — Nixpkgs overlays: `additions` (custom pkgs), `unstable-packages` (pkgs from nixpkgs-unstable).

### Host Configuration (`hosts/`)

```
hosts/
  common/
    core/      # Applied to all hosts (locale, sops, sshd, nix settings, etc.)
    optional/  # Opt-in per host (audio, bluetooth, bspwm, docker, wifi, etc.)
    disks/     # Disk layout configs
  ganoslal/    # Primary workstation (dual-GPU, nvidia.nix)
  merlin/      # Framework 16 laptop (nixos-hardware module)
  wsl/         # Windows Subsystem for Linux
```

Each host's `default.nix` imports `hosts/common/core` and selects from `hosts/common/optional`.

### Home Manager Configuration (`home/gig/`)

```
home/gig/
  common/
    core/      # Applied everywhere (nushell, git, ssh, sops, starship, wezterm, vim, zsh)
    optional/  # Opt-in (bspwm, polybar, picom, bat, direnv, shellAliases, etc.)
  home.nix     # Base home config (imported by all host-specific configs)
  ganoslal.nix / merlin.nix / wsl.nix / spacedock.nix  # Host entry points
```

Host-specific home files import `home.nix` and add host-appropriate optionals.

### Scripts as Packages

Scripts in `scripts/` are wrapped as Nix packages in `pkgs/scripts.nix` using `makeScriptPackage`. To add a new script: write it in `scripts/`, add an entry in `pkgs/scripts.nix`, then expose it via `pkgs/default.nix` and add to devShell in `flake.nix` if needed.

The `roll-flow` package is a Nushell script (`scripts/roll-flow`) wrapped via `stdenv.mkDerivation` with a shell wrapper. Its short alias `rf` is also exposed.

## Roll Flow Git Workflow

This repo uses a structured multi-host git workflow:

| Branch | Purpose |
|--------|---------|
| `main` | Verified stable on ALL hosts |
| `rolling` | Integration branch (tested on some hosts) |
| `roll/N-MMDD-theme` | Numbered themed work batches |
| `feature/*` | Individual features or fixes |

```bash
just roll-start <theme>       # Create roll/N-MMDD-theme branch
just roll-integrate <branch>  # Merge feature into current roll
just roll-graduate            # roll → rolling (tested on target host)
just roll-promote             # rolling → main (verified on ALL hosts)
just roll-status              # Check current state
just roll-list                # List all roll branches
```

Never merge directly to `main`. Always flow through `rolling`. See `docs/guides/ROLL-FLOW-QUICKREF.md` for emergency procedures.

## Code Style

- **File naming**: kebab-case for .nix files
- **Imports**: relative paths with `./` prefix
- **Formatting**: `nixfmt-rfc-style` via pre-commit hooks (run automatically)
- **Linting**: `statix` (anti-patterns), `deadnix` (unused bindings)
- **Function params**: destructuring `{ pkgs, lib, ... }:`
- **Overridable defaults**: use `lib.mkDefault`

## Secrets Management

Secrets live in a separate private repo (`~/nix-secrets/`) managed with SOPS + age keys. The `nix-secrets` flake input is a shallow SSH clone. Use `just sops` to edit secrets, `just rekey` to rotate keys. The `just dont-fuck-my-build` step (run before every rebuild) updates the nix-secrets flake lock.

## Worktree Safety

Active worktrees live under `./worktrees/`. Never modify files inside `./worktrees/` unless the session was explicitly started from within one. Always check `pwd` and `git branch --show-current` to confirm context. Use relative paths from the repo root (not `~/.dotfiles/` absolute paths) so code works correctly from worktrees.

## Operations & Documentation

- **Quest reports**: `operations/reports/away-reports/YYYY-MM-DD_[type].md`
- **Engineering logs**: `.tmp-oc-logs/` during development; archive to `~/local_repos/annex/` before branch completion
- **Enhancement Protocols (SEP)**: `engineering/enhancement-protocols/` for substantial feature work
- **Fleet operations manual**: `operations/fleet-management/OPERATIONS-MANUAL.md`
