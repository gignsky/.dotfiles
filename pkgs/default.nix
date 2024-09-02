# You can build these directly using 'nix build .#example'

{
  pkgs ? import <nixpkgs> { },
}:
rec {
  #################### Example Packages #################################
  example = pkgs.writeShellScriptBin "example" ''
    ${pkgs.cowsay}/bin/cowsay "hello world" | ${pkgs.lolcat}/bin/lolcat
  '';

  #################### Packages with external source ####################
  als = pkgs.callPackage ./als { };

}
