{ inputs, ... }:
{
  # https://notashelf.github.io/nvf/index.xhtml
  imports = [
    inputs.nvf.homeManagerModules.default
  ];
  programs.nvf = {
    enable = true;
    settings = {
      vim = {
        viAlias = true;
        vimAlias = true;
        lsp = {
          enable = true;
        };
        languages = {
          nix.enable = true;
          rust.enable = true;
          python.enable = false;
          markdown.enable = true;
          html.enable = true;
          sql.enable = true;
        };
        clipboard.enable = true;
        globals = {
          mapleader = " ";
          maplocalleader = " ";
        };
        utility = {
          icon-picker.enable = true;
        };
      };
    };
  };

}
