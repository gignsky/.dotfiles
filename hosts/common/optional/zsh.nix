{ pkgs, ... }: {
  users.defaultUserShell = pkgs.zsh;
  environment.shells = [ pkgs.zsh pkgs.nushell ];

  programs.zsh = {
    enable = true;

    # history = {
    #   size = lib.mkDefault 10000;
    #   path = lib.mkDefault "/home/gig/.zsh_history";
    # };
  };
  programs.nushell.enable = true;
}
