# 📄 pkgs/container-packages/default.nix (Simplified Module Collector)

{
  lib,
  ...
}: # configLib is no longer needed in the signature here
{
  # REMOVE: imports = configLib.scanPaths ./.;
  # The actual list of modules is now handled by the caller (pkgs/default.nix).

  # Define the required options structure
  options.dotspacedock.packages.container-packages = lib.mkOption {
    type = lib.types.attrsOf lib.types.package;
    default = { };
    description = "Packages defined in container-packages modules.";
  };
}
