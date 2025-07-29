{ inputs, ... }:
{
  # https://notashelf.github.io/nvf/index.xhtml
  imports = [
    # inputs.nvf.homeManagerModules.default
    inputs.gigvim.homeManagerModules.gigvim
  ];

  programs.gigvim.enable = true;

  # programs.nvf = {
  #   enable = true;
  #   settings = {
  #     vim = {
  #       viAlias = true;
  #       vimAlias = true;
  #       lsp = {
  #         # This must be enabled for the language modules to hook into
  #         # the LSP API.
  #         enable = true;

  #         formatOnSave = true;
  #         lspkind.enable = false;
  #         lightbulb.enable = true;
  #         lspsaga.enable = false;
  #         trouble.enable = false;
  #       };
  #       languages = {
  #         enableFormat = true;
  #         enableExtraDiagnostics = true;
  #         enableTreesitter = true;
  #         nix.enable = true;
  #         rust = {
  #           enable = true;
  #           crates.enable = true;
  #         };
  #         python.enable = false;
  #         markdown.enable = true;
  #         html.enable = true;
  #         css.enable = false;
  #         sql.enable = true;
  #         bash.enable = true;
  #         svelte.enable = false;
  #       };
  #       visuals = {
  #         nvim-scrollbar.enable = true;
  #         nvim-web-devicons.enable = true;
  #         nvim-cursorline.enable = true;
  #         cinnamon-nvim.enable = false;
  #         fidget-nvim.enable = false;
  #         highlight-undo.enable = true;
  #         indent-blankline.enable = true;

  #         # noted as fun :)
  #         cellular-automaton.enable = false;
  #       };
  #       statusline = {
  #         lualine = {
  #           enable = true;
  #           theme = "catppuccin";
  #         };
  #       };
  #       theme = {
  #         enable = true;
  #         name = "catppuccin";
  #         style = "mocha";
  #         transparent = false;
  #       };
  #       clipboard.enable = true;
  #       globals = {
  #         mapleader = " ";
  #         maplocalleader = " ";
  #       };
  #       utility = {
  #         icon-picker.enable = true;
  #       };
  #     };
  #   };
  # };

}
