{
  options,
  pkgs,
  optnixInput ? null,
  lib,
  config,
  ...
}:
lib.mkIf (optnixInput != null) (
  let
    optnixLib = optnixInput.mkLib pkgs;
  in
  {
    imports = [
      optnixInput.homeModules.optnix
    ];

    programs.optnix = {
      enable = false;
      settings = {
        min_score = 1;

        scopes = {
          home = {
            description = "home-manager configuration for all systems";
            options-list-file = optnixLib.mkOptionsList {
              inherit options;
              transform =
                o:
                o
                // {
                  name = lib.removePrefix "home-manager.users.${config.home.username}." o.name;
                };
            };
            evaluator = "";
          };
        };
      };
    };
  }
)
