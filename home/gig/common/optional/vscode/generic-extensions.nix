{ inputs, outputs, pkgs, ... }:

{
    # info at
    # https://nixos.wiki/wiki/Visual_Studio_Code
    ##############################################

    # Home Manager Way
    programs.vscode = {
        enable = true;
        extensions = with pkgs.vscode-extensions; [
            # bbenoist
            # nix
            ms-vscode-remote.remote-ssh
        ];
    };
}
