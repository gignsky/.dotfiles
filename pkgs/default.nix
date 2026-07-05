# You can build these directly using 'nix build .#example'

{
  pkgs ? import <nixpkgs> { },
}:
let
  # Import packaged scripts
  scripts = import ./scripts.nix { inherit pkgs; };
in
rec {
  #################### Example Packages #################################
  # example = pkgs.writeShellScriptBin "example" ''
  #   ${pkgs.cowsay}/bin/cowsay "hello world" | ${pkgs.lolcat}/bin/lolcat 2> /dev/null
  # '';

  #################### Packages with external source ####################
  # zsh-als-aliases = pkgs.callPackage ./zsh-als-aliases { }; # Removed as unnecessary but left for help in the future

  #################### Packaged Scripts ####################
  # Import all packaged scripts from scripts.nix
  inherit (scripts)
    check-hardware-config
    nixos-rebuild
    home-switch
    flake-build
    pre-commit-flake-check
    run-iso-vm
    package-script
    ;
}
