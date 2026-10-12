# The fleet binary cache server: Harmonia serves this host's store, and the
# builder + watcher keep it stocked. Module lives in modules/nixos/binary-cache
# (imported fleet-wide via hosts/common/core/binary-cache.nix). Import this
# file into any host's default.nix to make IT the server — the signing-key
# secret name and the excluded-from-targets host both follow
# `config.networking.hostName` automatically. Moving the server also means
# updating `vars/binary-cache.nix` (url/publicKey/serverHost/sshTarget) so
# clients and `just cache-*` point at the new host.
# See docs/guides/BINARY-CACHE.md for key setup and operations.
{
  config,
  inputs,
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

  # Per-host secret name (e.g. `binary-cache/spacedock-signing-key`), so this
  # file works unmodified on whichever host imports it.
  signingKeySecret = "binary-cache/${config.networking.hostName}-signing-key";

  # Active hosts other than this server itself (its own closure is local anyway).
  hosts = lib.attrNames (
    lib.filterAttrs (name: active: active && name != config.networking.hostName) (
      import (configLib.relativeToRoot "vars/hosts.nix")
    )
  );
  dotfiles = "git+ssh://git@github.com/gignsky/.dotfiles?ref=main&lfs=1";

  # Every gigpkgs package (its `packages.x86_64-linux` output), on both
  # channels the fleet rides. The package *names* come from the locked flake
  # inputs, so new gigpkgs packages are picked up on the next `flake.lock`
  # update; the builds themselves re-resolve the branch ref every run. The
  # roll-flow pins share derivations with roll-flow's own builds (see watch).
  gigpkgsChannels = {
    gigos-2605 = inputs.nixpkgs;
    gigos-unstable = inputs.nixpkgs-unstable;
  };
  # Heavy upstream (legacyPackages) builds worth caching that gigpkgs doesn't
  # expose as its own packages.
  extraChannelPackages = [
    "fastfetch"
    "bambu-studio"
  ];
  gigpkgsTargets = builtins.listToAttrs (
    lib.concatLists (
      lib.mapAttrsToList (
        channel: input:
        map (pkg: {
          name = "${channel}-${pkg}";
          value = "git+https://github.com/gignsky/gigpkgs?ref=${channel}#\"${pkg}\"";
        }) (lib.unique (lib.attrNames input.packages.x86_64-linux ++ extraChannelPackages))
      ) gigpkgsChannels
    )
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
    ${signingKeySecret} = { };
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
      signingKeyFile = config.sops.secrets.${signingKeySecret}.path;
      trustedPushers = [ configVars.username ];
      # Push-on-build from every other host (client.pushOnBuild); empty until
      # the key is generated, which leaves the account uncreated.
      pushUser.authorizedKeys = lib.optional (
        configVars.binaryCache.pushPublicKey != null
      ) configVars.binaryCache.pushPublicKey;
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
