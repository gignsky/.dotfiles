{
  inputs,
  configLib,
  lib,
  ...
}:
# roll-flow (rf) Home-Manager module, redistributed via gigpkgs.
# Auto-absorbed by home/gig/common/core/default.nix (`lib.scanPaths ./.`).
#
# Enables the `rf` binary in gig's profile and provides roll-flow config.
#
# Linked design:
#   - gignsky/roll-flow#55  layered config (fleet + per-repo — the multi-repo
#                           schema staged below), tri-state override,
#                           keying by normalized upstream remote.
#   - gignsky/roll-flow#56  verification/gating generalization (host -> target).
#   - gignsky/gigpkgs#14    gigpkgs channels; gigpkgs's rolling branch is `master`.
#   - gignsky/.dotfiles#14  spacedock bring-up (why it's listed but inactive).
let
  # Single source of truth: pull identity + host activity from the flake's own
  # vars rather than hardcoding (gignsky/roll-flow#55). `vars/hosts.nix` is a
  # plain { <host> = <bool>; } map — exactly roll-flow's `host_active`.
  configVars = import (configLib.relativeToRoot "vars") { inherit lib; };
  hostActive = import (configLib.relativeToRoot "vars/hosts.nix");
in
{
  # NOTE: once gigpkgs becomes the nixpkgs drop-in (gignsky/gigpkgs#14, fig.2)
  # and redistributes its modules through that nixpkgs, this explicit
  # `inputs.gigpkgs.*` import becomes unnecessary — the module would arrive via
  # the gigpkgs-that-is-nixpkgs. Kept explicit until #14 lands.
  imports = [ inputs.gigpkgs.homeManagerModules.roll-flow ];

  programs.roll-flow = {
    enable = true;

    # CURRENT single-repo schema, templated from the flake's vars.
    #
    # NOTE: roll-flow does not yet read this user-level config at runtime — the
    # binary resolves per-repo `<repo>/.roll-flow.toml` (see roll-flow#55). This
    # still installs `rf` into gig's profile and generates the config file, so it
    # is ready the moment #55's resolution chain lands.
    settings = {
      repo_root = configVars.dotfiles_dir;
      rolling_branch = "rolling";
      stable_branch = "main";
      roll_prefix = "roll/";
      username = configVars.username;
      hosts = builtins.attrNames hostActive; # [ ganoslal merlin spacedock wsl ]
      host_active = hostActive; # verbatim from vars/hosts.nix
    };
  };

  # ── Pending gignsky/roll-flow#55 — multi-repo fleet/repos schema ────────────
  # The single-repo `settings` above can only describe ONE repo. Once #55's
  # Home-Manager module lands (fleet topology + per-repo entries keyed by
  # normalized upstream remote, with the tri-state `override`), the block above
  # is replaced by the three-repo config below — dotfiles, roll-flow, gigpkgs,
  # each per its own issue:
  #
  # programs.roll-flow.fleet = {
  #   username = configVars.username;
  #   hosts.ganoslal.enabled  = false;
  #   hosts.merlin.enabled    = true;
  #   hosts.wsl.enabled       = true;
  #   hosts.spacedock.enabled = false;   # gignsky/.dotfiles#14
  #   override = "disabled";             # tri-state: true | false | "disabled"
  # };
  # programs.roll-flow.repos = {
  #   # keyed by normalized upstream remote (roll-flow#55 decision)
  #   "github.com/gignsky/.dotfiles" = { rolling_branch = "rolling"; stable_branch = "main"; };
  #   "github.com/gignsky/roll-flow" = { rolling_branch = "develop"; stable_branch = "main"; };
  #   # gigpkgs: rolling = master, which promotes (gated) into the base channel
  #   # that is then compounded with gigpkgs's HM/NixOS modules + overlays to form
  #   # the gigos-* channels. Exact stable target is being finalized in gigpkgs#14.
  #   "github.com/gignsky/gigpkgs"   = { rolling_branch = "master"; stable_branch = "gigpkgs-unstable"; };
  # };
}
