{ inputs, outputs, configLib, pkgs, ... }:

{
    imports = (configLib.scanPaths ./.);

    home.packages = with pkgs; [
	  vscode
    ];
}
