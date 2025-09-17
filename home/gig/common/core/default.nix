{ lib, flakeRoot, ... }:
let
  configLib = import (flakeRoot + /lib) { inherit lib; };
in
{
  imports = configLib.scanPaths ./.;
}
