{ options
, pkgs
, inputs
, lib
, config
, ...
}:
let
  optnixLib = inputs.optnix.mkLib pkgs;
in
{
  imports = [
    inputs.optnix.homeModules.optnix
  ];

  programs.optnix = {
    enable = true;
    settings = {
      min_score = 1;

      scopes = {
        home = {
          description = "home-manager configuration for all systems";
          options-list-file = optnixLib.mkOptionsList {
            inherit options;
            transform = o:
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
