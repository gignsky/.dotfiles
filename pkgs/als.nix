{
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem,
  fetchgit ? pkgs.fetchgit,
}:

let
  pname = "als";
  install_path = "share/zsh/${pname}";
in
{
  inherit pname;
  version = "";
  # Import src from github
  src = fetchgit {
    url = "https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/aliases";
    hash = "";
  };
  

}
