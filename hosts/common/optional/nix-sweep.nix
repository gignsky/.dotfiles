{ outputs, pkgs, ... }:
let
  inherit (pkgs.stdenv.hostPlatform) system;
in
{
  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.local-packages
      outputs.overlays.unstable-packages
    ];
  };
  environment.systemPackages = [
    pkgs.local.nix-sweep.packages.${system}.default
  ];
}
