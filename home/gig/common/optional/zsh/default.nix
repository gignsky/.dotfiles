{ pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    autocd = true;
    syntaxHighlighting.enable = true;

    shellAliases = import ../shellAliases.nix;

    # history = {
    #   # save = true;
    #   size = 10000;
    #   # ignoreDuplicates = true;
    #   # ignoreSpace = true;
    #   # share = true;
    #   # path = "${config.xdg.dataHome}/zsh/history"; # Suggested from https://nixos.wiki/wiki/Zsh
    #   path = "/home/gig/.zsh_history";
    # };

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];

    zplug = {
      enable = true;
      plugins = [
        { name = "zsh-users/zsh-autosuggestions"; } # Simple plugin installation
        # { name = "zsh-users"; plugin = "zsh-completions"; }
        # { name = "zsh-users"; plugin = "zsh-syntax-highlighting"; }
        # { name = "zsh-users"; plugin = "zsh-history-substring-search"; }
        # { name = "spwhitt"; plugin = "nix-zsh-completions"; }
        # { name = "softmoth"; plugin = "zsh-vim-mode"; }
        # { name = "desyncr"; plugin = "auto-ls"; }
      ];
    };
  };

  home.file.".p10k.zsh".source = ../../resources/.p10k.zsh;

  home.packages = [ pkgs.direnv ];

}
