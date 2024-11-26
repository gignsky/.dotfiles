{ inputs, outputs, configLib, pkgs, ... }:

{
    imports = (configLib.scanPaths ./.);

    #home.packages = with pkgs; [
	 # vscode
    #];

    # home.packages = with pkgs; [
	#   (vscode-with-extensions.override {
    #     vscodeExtensions = with vscode-extensions; [
    #         bbenoist.nix # nix language package
    #         # ms-python.python # python extension
    #         ms-vscode-remote.remote-ssh
    #     ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
    #         # {
    #         #     name = "remote-ssh-edit";
    #         #     publisher = "ms-vscode-remote";
    #         #     version = "0.47.2";
    #         #     sha256 = "1hp6gjh4xp2m1xlm1jsdzxw9d8frkiidhph6nvl24d0h8z34w49g";
    #         # }
    #     ];
    #   })
    # ];
}
