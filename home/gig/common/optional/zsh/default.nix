{ pkgs, zsh_plugins, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    autocd = true;
    syntaxHighlighting.enable = true;

    shellAliases = import ./shellAliases.nix;

    # history = {
    #   # save = true;
    #   size = 10000;
    #   # ignoreDuplicates = true;
    #   # ignoreSpace = true;
    #   # share = true;
    #   # path = "${config.xdg.dataHome}/zsh/history"; # Suggested from https://nixos.wiki/wiki/Zsh
    #   path = "/home/gig/.zsh_history";
    # };

    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = with zsh_plugins; trace "++zsh plugin list: ${lib.concatMapStringsSep "," (x: x.name) plugin_list}" plugin_list;
    };
  };
}
