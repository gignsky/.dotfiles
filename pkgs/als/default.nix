{
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem,
  fetchgit ? pkgs.fetchgit,
  # lib ? pkgs.lib,
}:

let
  pname = "als";
  install_path = "share/zsh/${pname}";
in
pkgs.stdenv.mkDerivation {
# {
  inherit pname;
  version = "0.0.1";
  # Import src from github
  src = fetchgit {
    url = "https://github.com/ohmyzsh/ohmyzsh.git";
    hash = "sha256-RGomSLwXoQDFkq1kFWfFMRdMmpW4dlLQ4JR5EDXW3/8=";
  };

  strictDeps = true;
  dontBuild = true;
  buildInputs = [ pkgs.python3 ];
  nativeBuildInputs = [ pkgs.patch ];

  patchPhase = ''
    cd $src/plugins/aliases/
    patch -p1 < ${./aliases.plugin.zsh.patch}
  '';

  installPhase = ''
    mkdir -p $out/${install_path}
    cd $src/plugins/aliases/
    cp aliases.plugin.zsh $out/${install_path}/
    cp cheatsheet.py $out/${install_path}/
    cp termcolor.py $out/${install_path}/
  '';

#   meta = with lib; {
#     # homepage = "https://github.com/mollifier/cd-gitroot";
#     license = licenses.mit;
#     longDescription = ''
#       zsh plugin to change directory to git repository root directory.
#           You can add the following to your `programs.zsh.plugins` list:
#           ```nix
#           programs.zsh.plugins = [
#             {
#               name = "${pname}";
#               src = "''${pkgs.${pname}}/${install_path}";
#             }
#           ];
#           ```
#     '';
#     # maintainers = with maintainers; [ gignsky ];
# }
}
