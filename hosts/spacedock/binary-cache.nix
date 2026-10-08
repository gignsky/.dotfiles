# Spacedock is the fleet binary cache: Harmonia serves its store, and the
# builder + watcher keep it stocked. Module lives in modules/nixos/binary-cache
# (imported fleet-wide via hosts/common/core/binary-cache.nix).
# See docs/guides/BINARY-CACHE.md for key setup and operations.
{
  config,
  lib,
  configLib,
  configVars,
  ...
}:
let
  # Flip once a read-only deploy key for gignsky/.dotfiles + gignsky/nix-secrets
  # is stored at `binary-cache/builder-github-key` in nix-secrets. Until then
  # host closures reach the cache via `just cache-push` instead.
  haveDeployKey = false;

  # Active hosts other than spacedock itself (its own closure is local anyway).
  hosts = lib.attrNames (
    lib.filterAttrs (name: active: active && name != config.networking.hostName) (
      import (configLib.relativeToRoot "vars/hosts.nix")
    )
  );
  dotfiles = "git+ssh://git@github.com/gignsky/.dotfiles?ref=main&lfs=1";

  # Large gigpkgs packages, on both channels the fleet rides. The roll-flow
  # pins share derivations with roll-flow's own builds (see watch below).
  gigpkgsPackages = [
    "roll-flow"
    "roll-flow-0.2.5"
    "roll-flow-0.2.6-dev"
    "gigvim-full"
    "claude-desktop"
    "fastfetch"
    "bambu-studio"
  ];
  gigpkgsTargets = builtins.listToAttrs (
    lib.concatMap
      (
        channel:
        map (pkg: {
          name = "${channel}-${pkg}";
          value = "git+https://github.com/gignsky/gigpkgs?ref=${channel}#\"${pkg}\"";
        }) gigpkgsPackages
      )
      [
        "gigos-2605"
        "gigos-unstable"
      ]
  );

  dotfilesTargets = builtins.listToAttrs (
    builtins.concatMap (host: [
      {
        name = "${host}-system";
        value = "${dotfiles}#nixosConfigurations.${host}.config.system.build.toplevel";
      }
      {
        name = "${host}-home";
        value = "${dotfiles}#homeConfigurations.\"gig@${host}\".activationPackage";
      }
    ]) hosts
  );
in
{
  sops.secrets = {
    "binary-cache/spacedock-signing-key" = { };
  }
  // (
    if haveDeployKey then
      {
        "binary-cache/builder-github-key".owner = config.binaryCache.user;
      }
    else
      { }
  );

  binaryCache = {
    sshKeyFile =
      if haveDeployKey then config.sops.secrets."binary-cache/builder-github-key".path else null;

    server = {
      enable = true;
      signingKeyFile = config.sops.secrets."binary-cache/spacedock-signing-key".path;
      trustedPushers = [ configVars.username ];
    };

    builder = {
      enable = true;
      targets = gigpkgsTargets // (if haveDeployKey then dotfilesTargets else { });
    };

    watch = {
      enable = true;
      pokeUsers = [ configVars.username ];
      # Every roll-flow branch head, plus release tags. gigpkgs pins roll-flow
      # without `follows`, so these are the exact derivations gigpkgs (and
      # this repo's devShell) evaluate — verified identical .drv paths.
      repos.roll-flow = {
        url = "https://github.com/gignsky/roll-flow";
        flake = "github:gignsky/roll-flow";
        branches = [
          "main"
          "develop"
          "roll/*"
        ];
        tags = [ "v*" ];
      };
    };
  };
}
