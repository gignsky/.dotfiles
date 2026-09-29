# Shared nix daemon configuration for all hosts.
#
# Previously each host (ganoslal, merlin) duplicated this block and wsl had no
# registry at all. Centralised here (auto-imported via common/core scanPaths) so
# every host gets a consistent flake registry + nix path, plus friendly gigpkgs
# channel handles for `nix shell <name>#pkg`.
{
  inputs,
  lib,
  config,
  ...
}:
let
  flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;

  # Live git handle for a gigpkgs branch (ref = null -> repo default branch).
  # These resolve at use-time, so pointing at branches that do not exist yet
  # (gigpkgs-*, *-stable — created later by gigpkgs CI) is fine; they simply
  # fail to fetch until the branch exists.
  #
  # Uses `type = "git"` rather than `type = "github"`: the github fetcher
  # resolves a branch ref via the GitHub REST API (unauthenticated, 60
  # req/hr), while the git fetcher resolves it via `git ls-remote` directly
  # against GitHub, which isn't subject to that limit.
  gigpkgsRef = ref: {
    to = {
      type = "git";
      url = "https://github.com/gignsky/gigpkgs.git";
    }
    // lib.optionalAttrs (ref != null) { inherit ref; };
  };

  # Dotless registry handles (a `.` will not parse as a flakeref id on the CLI),
  # each pointing at the correspondingly-named gigpkgs branch:
  #   gigpkgs        -> master trunk
  #   gigos-*        -> raw channel projections (channel.nix overwrite only)
  #   gigpkgs-*      -> relocked channel branches (created by gigpkgs CI)
  gigpkgsRegistry = {
    gigpkgs = gigpkgsRef null;
    "gigos-unstable" = gigpkgsRef "gigos-unstable";
    "gigos-2605" = gigpkgsRef "gigos-2605";
    "gigos-stable" = gigpkgsRef "gigos-stable";
    "gigpkgs-unstable" = gigpkgsRef "gigpkgs-unstable";
    "gigpkgs-stable" = gigpkgsRef "gigpkgs-stable";
    "gigpkgs-master" = gigpkgsRef null;
  };
in
{
  nix = {
    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Opinionated: disable global registry # Turned off the opinion by commenting below out
      # flake-registry = "";
      # Workaround for https://github.com/NixOS/nix/issues/9574
      nix-path = config.nix.nixPath;
    };
    # Opinionated: disable channels
    channel.enable = false;

    # Opinionated: make flake registry and nix path match flake inputs, and add
    # the gigpkgs channel aliases on top.
    registry = lib.mkForce (
      (lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs) // gigpkgsRegistry
    );
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  };
}
