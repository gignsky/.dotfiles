{ inputs, pkgs, ... }:

{
  home.packages = [
    # inputs.neve.packages.${pkgs.system}.default
    # pkgs.lunarvim
    # pkgs.neovim
  ];
  imports = [ inputs.nvf.homeManagerModules.default ];

  programs.nvf = {
    enable = true;
    settings = { };
  };
}
