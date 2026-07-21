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

  # Live github handle for a gigpkgs branch (ref = null -> default branch/master).
  # These resolve at use-time, so pointing at branches that do not exist yet
  # (gigpkgs-*, *-stable — created later by gigpkgs CI) is fine; they simply
  # fail to fetch until the branch exists.
  gigpkgsRef = ref: {
    to = {
      type = "github";
      owner = "gignsky";
      repo = "gigpkgs";
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
    "gigos-2605" = gigpkgsRef "gigos-26.05";
    "gigos-stable" = gigpkgsRef "gigos-stable";
    "gigpkgs-unstable" = gigpkgsRef "gigpkgs-unstable";
    "gigpkgs-2605" = gigpkgsRef "gigpkgs-26.05";
    "gigpkgs-stable" = gigpkgsRef "gigpkgs-stable";
  };
in
{
  nix = {
    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Opinionated: disable global registry
      flake-registry = "";
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
