{ inputs, outputs, pkgs, ... }:

{
    # info at
    # https://nixos.wiki/wiki/Visual_Studio_Code
    ##############################################

    # Home Manager Way
    programs = {
        vscode = {
            enable = true;
            enableExtensionUpdateCheck = true;
            enableUpdateCheck = true;
            mutableExtensionsDir = false; # disallows vscode from installing its own extensions
            # copy and paste user settings into the field below
            userSettings = {};

            extensions = with pkgs.vscode-extensions; [
                # bbenoist
                # nix
                ms-vscode-remote.remote-ssh
            ];
        };

        # A "wonderful CLI to track your time"
        watson = {
            enable = false;
            enableZshIntegration = true;
        };
    };
}
