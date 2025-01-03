{ pkgs, ... }:

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

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      # {
      #   name = "als";
      #   src = "${pkgs.als}/share/zsh/als";
      #   file = "share/zsh/als/aliases.plugin.zsh";
      # }
    ];

    # oh-my-zsh.enable = false;
    # oh-my-zsh.plugins = [
    #   "direnv"
    # ];

    zplug = {
      enable = true;
      plugins = [
        { name = "zsh-users/zsh-autosuggestions"; }
        { name = "plugins/git"; tags = ["from:oh-my-zsh"]; } # Plugin from oh-my-zsh
        { name = "plugins/sudo"; tags = ["from:oh-my-zsh"]; } # Plugin from oh-my-zsh
        { name = "plugins/colored-man-pages"; tags = ["from:oh-my-zsh"]; } # Plugin from oh-my-zsh
        { name = "plugins/command-not-found"; tags = ["from:oh-my-zsh"]; } # Plugin from oh-my-zsh
        { name = "plugins/aliases"; tags = ["from:oh-my-zsh"]; } # being substituted by custom package
        { name = "plugins/ansible"; tags = ["from:oh-my-zsh"]; } # Plugin from oh-my-zsh
        # { name = "plugins/direnv"; tags = ["from:oh-my-zsh"]; } # Unneccecary
        # { name = "plugins/virtualenvwrapper"; tags = ["from:oh-my-zsh"]; } # Plugin from oh-my-zsh
        # { name = "plugins/copybuffer"; tags = ["from:oh-my-zsh"]; } # Plugin from oh-my-zsh
        # { name = "plugins/cp"; tags = ["from:oh-my-zsh"]; } # Plugin from oh-my-zsh
        # { name = "zsh-users/zsh-syntax-highlighting";}
        # { name = "zsh-users/zsh-autosuggestions";}
        # { name = "zsh-users/zsh-completions";}
        # { name = "djui/alias-tips";}
        { name = "zpm-zsh/ls";}
        { name = "zpm-zsh/colors";}
        # { name = "zpm-zsh/dircolors-neutral";} #depreciated look for an alt
        # { name = "dbz/kube-aliases";}
        # { name = "zsh-users"; plugin = "zsh-completions"; }
        # { name = "zsh-users"; plugin = "zsh-syntax-highlighting"; }
        # { name = "zsh-users"; plugin = "zsh-history-substring-search"; }
        # { name = "spwhitt"; plugin = "nix-zsh-completions"; }
        # { name = "softmoth"; plugin = "zsh-vim-mode"; }
        # { name = "desyncr"; plugin = "auto-ls"; }
      ];
    };
  };

  home.file.".p10k.zsh".source = ../resources/.p10k.zsh.vm;

  home.packages = [ pkgs.direnv ];

}
