{ config, lib, pkgs, isWSL ? false, ... }:

let
  extensionIds = import ../vscode-extensions-list.nix;
  extensions = builtins.map (id: pkgs.vscode-extensions.${id}) extensionIds;
  scriptPath = "${config.home.homeDirectory}/.dotfiles/scripts/install-vscode-extensions-wsl.sh";
in
lib.mkMerge [
  (lib.mkIf isWSL {
    home.activation.vscodeExtensionsWSL = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      chmod +x ${scriptPath} || true
      ${scriptPath} || true
    '';
  })
  (lib.mkIf (!isWSL) {
    # info at
    # https://nixos.wiki/wiki/Visual_Studio_Code
    ##############################################

    # search extentions at
    # https://search.nixos.org/packages?type=packages&query=vscode-extensions
    ##############################################

    # Home Manager Way
    programs.vscode = {
      enable = false;
      enableExtensionUpdateCheck = true;
      enableUpdateCheck = true;
      mutableExtensionsDir = false; # disallows vscode from installing its own extensions
      userSettings = { };
      extensions = extensions;
    };
    # # A "wonderful CLI to track your time"
    # watson = {
    #     enable = false;
    #     enableZshIntegration = true;
    # };
  })
]
