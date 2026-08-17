# LaTeX Configuration - Full TeX Live toolchain with declarative build automation
# https://www.tug.org/texlive/
# Editor integration (LSP, syntax) is handled by gigvim; PDF viewing by the
# existing pdfarranger/pdf4qt packages. This module only owns the toolchain.
{ pkgs, ... }:
{
  home.packages = [
    # Full scheme so no package is ever missing while learning LaTeX.
    pkgs.texlive.combined.scheme-full
  ];

  # Declarative build automation: latexmk watches/builds/cleans without a
  # per-project Makefile. `latexmk -pvc file.tex` builds on every save.
  home.file.".latexmkrc".text = ''
    $pdf_mode = 1;
    $synctex = 1;
    $pdf_previewer = 'none';
    $clean_ext = 'synctex.gz synctex.gz(busy) run.xml bbl bcf fdb_latexmk run tdo';
  '';

  home.sessionVariables = {
    # Conventional local texmf tree for custom .sty/.cls files, kept out of
    # the read-only Nix store texlive package.
    TEXMFHOME = "$HOME/.texmf";
  };
}
