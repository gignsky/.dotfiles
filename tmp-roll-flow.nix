{
  inputs,
  configLib,
  lib,
  ...
}:
# roll-flow (rf) Home-Manager module, redistributed via gigpkgs.
#
# STAGED, NOT YET WIRED. Not under home/gig/common/core/ (which
# home/gig/common/core/default.nix auto-absorbs via `lib.scanPaths ./.`), so
# this plays no part in any build today. Move it there once both are true:
#   1. gigpkgs exports `homeManagerModules.roll-flow` (an
#      `modules/home/inputs/roll-flow.nix` aggregator, discovered by
#      `inputman update roll-flow` — see gigpkgs's existing
#      `modules/home/inputs/gigvim.nix` for the pattern). In progress as of
#      2026-10-06; not yet on any gigpkgs branch.
#   2. this flake's `nixpkgs` input (dotfiles consumes gigpkgs *as* nixpkgs,
#      so the module arrives as `inputs.nixpkgs.homeManagerModules.roll-flow`
#      — there is no separate `gigpkgs` input) is re-locked to a rev that
#      includes it: `nix flake lock --update-input nixpkgs`.
# Moving it in before both are true breaks every host's home-manager build,
# since the scanned directory is unconditional.
#
# Config shape here matches roll-flow's actual layered-config feature
# (gignsky/roll-flow, "feat(config): layer a machine-wide config under the
# repo file" — landed simpler than the fleet/repos/tri-state schema this file
# used to sketch below #55; that sketch is gone, not pending). This is the
# *global* layer every repo's own `<repo>/.roll-flow.toml` is laid over —
# repo-specific keys (repo_root, rolling_branch, stable_branch, roll_prefix,
# the gate arrays) stay in each repo's file, never here. See
# gignsky/roll-flow docs/nix-modules.md and docs/config.md#layers.
let
  configVars = import (configLib.relativeToRoot "vars") { inherit lib; };
  hostActive = import (configLib.relativeToRoot "vars/hosts.nix");
in
{
  imports = [ inputs.nixpkgs.homeManagerModules.roll-flow ];

  programs.roll-flow = {
    enable = true;
    settings = {
      username = configVars.username;
      hosts = builtins.attrNames hostActive; # [ ganoslal merlin spacedock wsl ]
      host_active = hostActive; # verbatim from vars/hosts.nix
    };
  };
}
