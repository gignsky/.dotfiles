# You can build these directly using 'nix build .#example'

{
  pkgs ? import <nixpkgs> { },
}:
rec {
  #################### Example Packages #################################
  # example = pkgs.writeShellScriptBin "example" ''
  #   ${pkgs.cowsay}/bin/cowsay "hello world" | ${pkgs.lolcat}/bin/lolcat
  # '';

  supertree = pkgs.writeShellScriptBin "supertree" ''
    ${pkgs.tree}/bin/tree ..
  '';

  quick-results = pkgs.writeShellScriptBin "quick-results" ''
    if [ -d ./result ]; then
      ${pkgs.tree}/bin/tree ./result
    else
      echo "No result directory found" | ${pkgs.cowsay}/bin/cowsay | ${pkgs.lolcat}/bin/lolcat
    fi
  '';

  #################### Packages with external source ####################
  zsh-als-aliases = pkgs.callPackage ./zsh-als-aliases { };

}
