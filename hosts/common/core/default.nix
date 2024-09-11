{ configLib, ... }:

{
    imports = (configLib.scanPaths ./.);

    nixpkgs = {
        # you can add global overlays here
        # overlays = builtins.attrValues outputs.overlays;
        config = {
        allowUnfree = true;
        };
    };

    # hardware.enableRedistributableFirmware = true;
}
