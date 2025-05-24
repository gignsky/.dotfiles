{ inputs, pkgs, ... }:

{

  imports = [ inputs.nvf.nixosModules.default ];

  programs.nvf = {
    enable = true;
    settings = { };
  };
}
