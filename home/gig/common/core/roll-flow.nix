{
  inputs,
  configLib,
  lib,
  ...
}:
# roll-flow (rf) Home-Manager module, redistributed via gigpkgs.
#
# WIRED as of 2026-10-07: gigpkgs now exports `homeManagerModules.roll-flow`
# (a `modules/home/inputs/roll-flow.nix` aggregator, same pattern as
# gigpkgs's `modules/home/inputs/gigvim.nix`), and this flake's `nixpkgs`
# input (dotfiles consumes gigpkgs *as* nixpkgs, so the module arrives as
# `inputs.nixpkgs.homeManagerModules.roll-flow` — there is no separate
# `gigpkgs` input) is locked to a rev that includes it
# (gigos-2605@62b40ada, 2026-10-06). Living under home/gig/common/core/ means
# home/gig/common/core/default.nix's `lib.scanPaths ./.` now picks this up
# for every host unconditionally.
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
      inherit (configVars) username;
      hosts = builtins.attrNames hostActive; # [ ganoslal merlin spacedock wsl ]
      host_active = hostActive; # verbatim from vars/hosts.nix
    };
  };
}
