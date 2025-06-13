{ inputs, outputs, configLib, pkgs, ... }:

{
  imports = configLib.scanPaths ./.;
}
