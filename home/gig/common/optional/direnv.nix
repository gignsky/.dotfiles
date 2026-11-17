{ configLib, pkgs, ... }:
let
  binaryCache = import (configLib.relativeToRoot "vars/binary-cache.nix");
  inherit (pkgs.callPackage (configLib.relativeToRoot "modules/nixos/binary-cache/package.nix") { })
    cache-push
    ;
in
{
  programs.direnv = {
    enable = true;
    enableNushellIntegration = false; # Disable automatic integration due to syntax issues
    enableZshIntegration = true;
    nix-direnv.enable = true;
    # Content-addressed multi-slot cache in front of nix-direnv's `use flake`,
    # so branch switches / rebuilds that touch flake.lock don't force a re-eval.
    # Freshly evaluated envs are pushed to the fleet binary cache in the
    # background (opt out per shell with FLAKE_CACHE_PUSH=0).
    stdlib = ''
      _flake_cache_push_cmd=(
        ${cache-push}/bin/cache-push
        --to ${binaryCache.sshTarget}
        --server-host ${binaryCache.serverHost}
      )
    ''
    + builtins.readFile (configLib.relativeToRoot "home/gig/common/resources/direnvrc-flake-cache.sh");
  };

  home.file.".config/direnv/direnv.toml".source =
    configLib.relativeToRoot "home/gig/common/resources/direnv.toml";
}
