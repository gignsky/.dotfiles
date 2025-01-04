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
    ];

    # Append custom content to the end of .zshrc
    initExtra = ''
      # ~/.zshrc

      # # alias-finder plugin's options from https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/alias-finder
      # zstyle ':omz:plugins:alias-finder' autoload yes # disabled by default
      # zstyle ':omz:plugins:alias-finder' longer yes # disabled by default
      # zstyle ':omz:plugins:alias-finder' exact no # disabled by default
      # zstyle ':omz:plugins:alias-finder' cheaper no # disabled by default

      # # Colorize option
      # ZSH_COLORIZE_TOOL=chroma
      # ZSH_COLORIZE_STYLE="colorful"

      # docker options
      zstyle ':completion:*:*:docker:*' option-stacking yes
      zstyle ':completion:*:*:docker-*:*' option-stacking yes

      # eza options
      zstyle ':omz:plugins:eza' 'dirs-first' yes
      zstyle ':omz:plugins:eza' 'git-status' yes
      zstyle ':omz:plugins:eza' 'header' yes
      zstyle ':omz:plugins:eza' 'show-group' yes
      zstyle ':omz:plugins:eza' 'icons' yes
      zstyle ':omz:plugins:eza' 'hyperlink' yes
    '';

    zplug = {
      enable = true;
      plugins = [
        { name = "zsh-users/zsh-autosuggestions"; }
        { name = "plugins/git"; tags = ["from:oh-my-zsh"]; } # Plugin from oh-my-zsh
        { name = "plugins/sudo"; tags = ["from:oh-my-zsh"]; } # Plugin from oh-my-zsh
        # { name = "plugins/colorize"; tags = ["from:oh-my-zsh"]; } # Plugin from oh-my-zsh
        { name = "plugins/common-aliases"; tags = ["from:oh-my-zsh"]; } # Plugin from oh-my-zsh
        { name = "plugins/colored-man-pages"; tags = ["from:oh-my-zsh"]; } # Plugin from oh-my-zsh
        { name = "plugins/command-not-found"; tags = ["from:oh-my-zsh"]; } # Plugin from oh-my-zsh
        { name = "plugins/aliases"; tags = ["from:oh-my-zsh"]; }
        # { name = "plugins/alias-finder"; tags = ["from:oh-my-zsh"]; } # not as easily readable as the one below
        { name = "akash329d/zsh-alias-finder"; } # better alias finder than above but doesn't have expansion as far as I can tell
        { name = "plugins/ansible"; tags = ["from:oh-my-zsh"]; } # Plugin from oh-my-zsh
        # { name = "plugins/virtualenvwrapper"; tags = ["from:oh-my-zsh"]; } # Plugin from oh-my-zsh
        { name = "plugins/copybuffer"; tags = ["from:oh-my-zsh"]; } # Plugin from oh-my-zsh
        { name = "plugins/copyfile"; tags = ["from:oh-my-zsh"]; } # Plugin from oh-my-zsh
        { name = "plugins/copypath"; tags = ["from:oh-my-zsh"]; } # Plugin from oh-my-zsh
        { name = "plugins/cp"; tags = ["from:oh-my-zsh"]; } # Plugin from oh-my-zsh
        { name = "plugins/docker"; tags = ["from:oh-my-zsh"]; } # Plugin from oh-my-zsh
        { name = "plugins/docker-compose"; tags = ["from:oh-my-zsh"]; } # Plugin from oh-my-zsh
        { name = "plugins/extract"; tags = ["from:oh-my-zsh"]; } # Plugin from oh-my-zsh
        { name = "plugins/eza"; tags = ["from:oh-my-zsh"]; } # Plugin from oh-my-zsh
        # { name = "z-shell/zsh-eza"; }
        { name = "plugins/fancy-ctrl-z"; tags = ["from:oh-my-zsh"]; } # Plugin from oh-my-zsh
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

  home.packages = with pkgs; [ 
    direnv
    python3 #needed for aliases plugin from oh-my-zsh and other alias plugin
    eza #needed for eza plugin
    # chroma #needed for colorize plugin from oh-my-zsh
  ];

}
