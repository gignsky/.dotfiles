{ pkgs, lib, ... }:

{
  users.defaultUserShell = pkgs.zsh;
  users.users.gig.shell = pkgs.zsh;
  environment.shells = [ pkgs.zsh ];

  programs.zsh = {
    enable = true;

    # history = {
    #   size = lib.mkDefault 10000;
    #   path = lib.mkDefault "/home/gig/.zsh_history";
    # };
  };
}
