{ inputs, outputs, configLib, pkgs, lib, ... }:

let
  extensionIds = import ../vscode-extensions-list.nix;
  extensions = builtins.map (id: pkgs.vscode-extensions.${id}) extensionIds;
in
{
  options.isWSL = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Set to true if running in WSL.";
  };

  config = config:
    if config.isWSL then {
      home.activation.vscodeExtensionsWSL = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${config.home.homeDirectory}/.dotfiles/scripts/install-vscode-extensions-wsl.sh || true
      '';
    } else {
      # info at
      # https://nixos.wiki/wiki/Visual_Studio_Code
      ##############################################

      # search extentions at
      # https://search.nixos.org/packages?type=packages&query=vscode-extensions
      ##############################################

      # Home Manager Way
      programs = {
        vscode = {
          enable = false;
          enableExtensionUpdateCheck = true;
          enableUpdateCheck = true;
          mutableExtensionsDir = false; # disallows vscode from installing its own extensions
          # copy and paste user settings into the field below
          userSettings = { };
          extensions = extensions;
        };

        # # A "wonderful CLI to track your time"
        # watson = {
        #     enable = false;
        #     enableZshIntegration = true;
        # };
      };
    };
}
