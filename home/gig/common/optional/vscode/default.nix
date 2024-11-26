{ inputs, outputs, configLib, ... }:

{
    imports = (configLib.scanPaths ./.);

    home.packages = with pkgs; [
	  vscode
    ];
}
