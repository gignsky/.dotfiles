{ options
, pkgs
, inputs
, ...
}:
let
  optnixLib = inputs.optnix.mkLib pkgs;
in
{
  imports = [
    inputs.optnix.nixosModules.optnix
  ];

  programs.optnix = {
    enable = true;
    settings = {
      min_score = 1;

      scopes = {
        wsl = {
          description = "NixOS config for wsl hosts";
          options-list-file = optnixLib.mkOptionsList { inherit options; };

          evaluator = "nix eval /home/gig/.dotfiles#nixosConfigurations.wsl.config.{{ .Option }}";
        };
      };
    };
  };
}
