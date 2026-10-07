# Timer that builds a fixed set of flake refs into this host's store and keeps
# each one GC-rooted, so the cache always has them.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config) binaryCache;
  cfg = binaryCache.builder;
  service = import ./service.nix { inherit lib binaryCache; };

  configFile = pkgs.writeText "binary-cache-build.json" (
    builtins.toJSON {
      inherit (binaryCache) stateDir;
      inherit (cfg) targets;
    }
  );
in
{
  options.binaryCache.builder = {
    enable = lib.mkEnableOption "scheduled builds of fixed flake targets";

    schedule = lib.mkOption {
      type = lib.types.str;
      default = "03:00";
      description = "systemd OnCalendar expression.";
    };

    targets = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        hello = "nixpkgs#hello";
        laptop-system = "git+ssh://git@github.com/me/dotfiles?ref=main#nixosConfigurations.laptop.config.system.build.toplevel";
      };
      description = ''
        Root name → installable. Each is rebuilt every run (refs are
        re-resolved, so branch refs track their head) and rooted at
        `''${stateDir}/roots/build/<name>`. Roots for removed names are pruned.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.binary-cache-build = service.mkService {
      description = "Build binary cache targets";
      script = "${lib.getExe binaryCache.package.cache-build} ${configFile}";
    };
    systemd.timers.binary-cache-build = service.mkTimer cfg.schedule;
  };
}
