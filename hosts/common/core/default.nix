{ pkgs, ... }:

{
    imports = [
        ./locale.nix
        ./sshd.nix
        ./shells.nix
    ];

    nixpkgs = {
        # you can add global overlays here
        # overlays = builtins.attrValues outputs.overlays;
        config = {
        allowUnfree = true;
        };
    };

    # hardware.enableRedistributableFirmware = true;
}
