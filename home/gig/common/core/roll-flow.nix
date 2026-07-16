{ inputs, ... }:
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
{
  imports = [ inputs.gigpkgs.homeManagerModules.roll-flow ];

  programs.roll-flow = {
    enable = true;

    # CURRENT single-repo schema (what the redistributed module supports today).
    # Configures THIS dotfiles repo. host_active mirrors vars/hosts.nix.
    #
    # NOTE: roll-flow does not yet read this user-level config at runtime — the
    # binary resolves per-repo `<repo>/.roll-flow.toml` (see roll-flow#55). This
    # still installs `rf` into gig's profile and generates the config file, so it
    # is ready the moment #55's resolution chain lands.
    settings = {
      repo_root = "/home/gig/.dotfiles";
      rolling_branch = "rolling";
      stable_branch = "main";
      roll_prefix = "roll/";
      username = "gig";
      hosts = [
        "ganoslal"
        "merlin"
        "wsl"
        "spacedock"
      ];
      host_active = {
        ganoslal = false;
        merlin = true;
        wsl = true;
        spacedock = false; # brought up in gignsky/.dotfiles#14
      };
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
  #   username = "gig";
  #   hosts.ganoslal.enabled  = false;
  #   hosts.merlin.enabled    = true;
  #   hosts.wsl.enabled       = true;
  #   hosts.spacedock.enabled = false;   # gignsky/.dotfiles#14
  #   override = "disabled";             # tri-state: true | false | "disabled"
  # };
  # programs.roll-flow.repos = {
  #   # keyed by normalized upstream remote (roll-flow#55 decision)
  #   "github.com/gignsky/.dotfiles" = { rolling_branch = "rolling"; stable_branch = "main"; };
  #   "github.com/gignsky/roll-flow" = { rolling_branch = "develop"; stable_branch = "main"; };  # roll-flow rolling = develop
  #   "github.com/gignsky/gigpkgs"   = { rolling_branch = "master";  stable_branch = "main"; };  # gigpkgs#14: rolling = master
  # };
}
