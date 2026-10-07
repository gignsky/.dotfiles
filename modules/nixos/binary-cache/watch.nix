# Poll git remotes and build every matching branch/tag head the moment it
# changes, so a push from any machine ends up cached.
#
# Builds `<flake>?rev=<sha>#<attr>` straight from the watched repo. That only
# yields cache hits for consumers that use the repo's OWN lock (i.e. they do not
# override its inputs with `follows`). If a consumer starts overriding, its
# derivation differs and these builds stop helping it.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config) binaryCache;
  cfg = binaryCache.watch;
  service = import ./service.nix { inherit lib binaryCache; };

  repoType = lib.types.submodule {
    options = {
      url = lib.mkOption {
        type = lib.types.str;
        example = "https://github.com/owner/repo";
        description = "Git URL polled with `git ls-remote`.";
      };
      flake = lib.mkOption {
        type = lib.types.str;
        example = "github:owner/repo";
        description = "Flake ref base; `?rev=<sha>` is appended.";
      };
      branches = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [
          "main"
          "roll/*"
        ];
        description = "Branch globs (`*` matches anything, including `/`).";
      };
      tags = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "v*" ];
        description = "Tag globs.";
      };
      attrs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "default" ];
        description = "Flake output attributes to build for each ref.";
      };
    };
  };

  units = [
    "binary-cache-watch.service"
    "binary-cache-build.service"
  ];

  configFile = pkgs.writeText "binary-cache-watch.json" (
    builtins.toJSON {
      inherit (binaryCache) stateDir;
      inherit (cfg) repos;
    }
  );
in
{
  options.binaryCache.watch = {
    enable = lib.mkEnableOption "building watched git refs as they change";

    interval = lib.mkOption {
      type = lib.types.str;
      default = "*:0/5";
      description = "systemd OnCalendar expression for polling.";
    };

    repos = lib.mkOption {
      type = lib.types.attrsOf repoType;
      default = { };
    };

    pokeUsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Users allowed to start the watch/build services early without sudo
        (`systemctl start binary-cache-watch`), e.g. over ssh right after a push.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.binary-cache-watch = service.mkService {
      description = "Build changed refs of watched repos";
      script = "${lib.getExe binaryCache.package.cache-watch} ${configFile}";
    };
    systemd.timers.binary-cache-watch = service.mkTimer cfg.interval;

    security.polkit = lib.mkIf (cfg.pokeUsers != [ ]) {
      enable = true;
      extraConfig = ''
        polkit.addRule(function (action, subject) {
          if (action.id == "org.freedesktop.systemd1.manage-units" &&
              ${builtins.toJSON units}.indexOf(action.lookup("unit")) >= 0 &&
              action.lookup("verb") == "start" &&
              ${builtins.toJSON cfg.pokeUsers}.indexOf(subject.user) >= 0) {
            return polkit.Result.YES;
          }
        });
      '';
    };
  };
}
