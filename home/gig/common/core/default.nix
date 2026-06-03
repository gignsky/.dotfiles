{ lib, ... }:
# let
#   configLib = import (flakeRoot + /lib) { inherit lib; };
# in
{
  imports = lib.scanPaths ./.;
}
