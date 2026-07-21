# Buzz Container Module
# Organized container functionality for spacedock replication.
# Ported from dot-spacedock. Not wired into flake outputs by default — see
# containers/README.md for how to expose the nixosConfiguration + packages
# (requires adding the `nixos-generators` flake input).

{
  inputs,
  lib,
  system,
  ...
}:

let
  # Import the buzz configuration
  buzzConfig = import ./config.nix;

  # Import buzz packages (both Docker and Podman versions)
  buzzPackagesDocker = import ./packages.nix;
  buzzPackagesPodman = import ./packages-podman.nix;

  # Get the main flake's configVars and other needed specialArgs
  configVars = import ../../vars { inherit inputs lib; };
  configLib = import ../../lib { inherit lib; };

  # Import overlays from main flake
  overlays = import ../../overlays { inherit inputs; };

  # Create a minimal outputs structure for buzz
  outputs = {
    inherit overlays;
  };

  buzzDocker = buzzPackagesDocker { inherit inputs lib system; };
  buzzPodman = buzzPackagesPodman { inherit inputs lib system; };
  buzzPackages = buzzPodman // buzzDocker; # Default to Docker version (wins on merge)

in
{
  # Expose the buzz NixOS configuration
  nixosConfiguration = inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = {
      inherit
        inputs
        lib
        system
        configVars
        configLib
        outputs
        ;
      nixpkgs = inputs.nixpkgs;
    };
    modules = [ buzzConfig ];
  };

  # Expose buzz-related packages
  packages = buzzPackages;
}
