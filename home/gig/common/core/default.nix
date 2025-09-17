{ lib, ... }:
let
  configLib = import ../../../lib { inherit lib; };
in
{
  imports = configLib.scanPaths ./.;
}
