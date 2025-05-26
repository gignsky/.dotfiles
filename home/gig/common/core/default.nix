{ inputs, outputs, configLib, ... }:

{
  imports = (configLib.scanPaths ./.);
}
