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
  version = "0.0.2";
  # Import src from github
  src = fetchgit {
    url = "https://github.com/ohmyzsh/ohmyzsh.git";
    hash = "sha256-DmEeorRfYdGTbXchxnzvr/iLgMx1DJMUmkYNMwjXqBM=";
  };

  strictDeps = true;
  dontBuild = true;
  buildInputs = [ ];
  nativeBuildInputs = [ pkgs.patch ];

  patchPhase = ''
    mkdir -p $out/${install_path}
    cd $src/plugins/aliases/

    cp aliases.plugin.zsh $out/${install_path}/

    cd $out/${install_path}/

    patch -p1 < ${./aliases.plugin.zsh.patch}

    substituteInPlace aliases.plugin.zsh \
      --replace 'python3' '${pkgs.python3}/bin/python3'
  '';

  installPhase = ''
    cd $src/plugins/aliases/
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
