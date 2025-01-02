{ inputs, outputs, configLib, pkgs, lib, ... }:

{
  options.vscodeIsWSL = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Set to true if running in WSL.";
  };

  imports = config: if config.vscodeIsWSL then ./wsl else ./regular;
}
