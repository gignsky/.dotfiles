{ pkgs, ... }:

{
    imports = [
        ./locale.nix
        ./sshd.nix
        ./shells.nix
        ./sops.nix
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
