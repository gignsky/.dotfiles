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
          enable = false;
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
