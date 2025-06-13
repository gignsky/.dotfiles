{ ... }:

{
  options.isWSL = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Set to true if running in WSL.";
  };

  imports = config: if config.isWSL then ./wsl else ./regular;
}
