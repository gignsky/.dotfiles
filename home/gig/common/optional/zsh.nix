{ pkgs, ... }:

{
  # home.file.".p10k.zsh".source = ../resources/.p10k.zsh.vm;
  imports = [
    ./starship.nix
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    autocd = true;
    syntaxHighlighting.enable = true;

    shellAliases = import ./shellAliases.nix;

    history = {
      append = true;
      extended = true;
      ignoreSpace = false;
      save = 2000;
      size = 100000;
      share = true;
      path = "/home/gig/.zsh_history";
    };

    # # Depreciated :(
    # plugins = [
    #   {
    #     name = "powerlevel10k";
    #     src = pkgs.zsh-powerlevel10k;
    #     file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
    #   }
    # ];

    #   # Append custom content to the end of .zshrc
    #   initContent = ''
    #     # ~/.zshrc

    #     # # alias-finder plugin's options from https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/alias-finder
    #     # zstyle ':omz:plugins:alias-finder' autoload yes # disabled by default
    #     # zstyle ':omz:plugins:alias-finder' longer yes # disabled by default
    #     # zstyle ':omz:plugins:alias-finder' exact no # disabled by default
    #     # zstyle ':omz:plugins:alias-finder' cheaper no # disabled by default

    #     # # Colorize option
    #     # ZSH_COLORIZE_TOOL=chroma
    #     # ZSH_COLORIZE_STYLE="colorful"

    #     # docker options
    #     zstyle ':completion:*:*:docker:*' option-stacking yes
    #     zstyle ':completion:*:*:docker-*:*' option-stacking yes

    #     # eza options
    #     zstyle ':omz:plugins:eza' 'dirs-first' yes
    #     zstyle ':omz:plugins:eza' 'git-status' yes
    #     zstyle ':omz:plugins:eza' 'header' yes
    #     zstyle ':omz:plugins:eza' 'show-group' yes
    #     zstyle ':omz:plugins:eza' 'icons' yes
    #     zstyle ':omz:plugins:eza' 'hyperlink' yes

    #     # fzf config
    #     export FZF_BASE=${pkgs.fzf}/bin/fzf
    #   '';

    #   zplug = {
    #     enable = true;
    #     plugins = [
    #       { name = "zsh-users/zsh-autosuggestions"; }
    #       { name = "plugins/git"; tags = [ "from:oh-my-zsh" ]; } # Plugin from oh-my-zsh
    #       { name = "plugins/git-auto-fetch"; tags = [ "from:oh-my-zsh" ]; } # Plugin from oh-my-zsh
    #       # { name = "plugins/git-commit"; tags = ["from:oh-my-zsh"]; } # Plugin from oh-my-zsh
    #       { name = "plugins/gitfast"; tags = [ "from:oh-my-zsh" ]; } # Plugin from oh-my-zsh
    #       { name = "plugins/git-flow-avh"; tags = [ "from:oh-my-zsh" ]; } # Plugin from oh-my-zsh NOT SURE WHAT GIT FLOW IS BUT KEEPING THIS HERE IN CASE I USE IT IN THE FUTURE
    #       { name = "plugins/gitignore"; tags = [ "from:oh-my-zsh" ]; } # Plugin from oh-my-zsh NOT SURE WHAT GIT FLOW IS BUT KEEPING THIS HERE IN CASE I USE IT IN THE FUTURE
    #       { name = "plugins/sudo"; tags = [ "from:oh-my-zsh" ]; } # Plugin from oh-my-zsh
    #       # { name = "plugins/colorize"; tags = ["from:oh-my-zsh"]; } # Plugin from oh-my-zsh
    #       { name = "plugins/common-aliases"; tags = [ "from:oh-my-zsh" ]; } # Plugin from oh-my-zsh
    #       { name = "plugins/colored-man-pages"; tags = [ "from:oh-my-zsh" ]; } # Plugin from oh-my-zsh
    #       { name = "plugins/command-not-found"; tags = [ "from:oh-my-zsh" ]; } # Plugin from oh-my-zsh
    #       { name = "plugins/aliases"; tags = [ "from:oh-my-zsh" ]; }
    #       # { name = "plugins/alias-finder"; tags = ["from:oh-my-zsh"]; } # not as easily readable as the one below
    #       { name = "akash329d/zsh-alias-finder"; } # better alias finder than above but doesn't have expansion as far as I can tell
    #       { name = "plugins/ansible"; tags = [ "from:oh-my-zsh" ]; } # Plugin from oh-my-zsh
    #       # { name = "plugins/virtualenvwrapper"; tags = ["from:oh-my-zsh"]; } # Plugin from oh-my-zsh
    #       { name = "plugins/copybuffer"; tags = [ "from:oh-my-zsh" ]; } # Plugin from oh-my-zsh
    #       { name = "plugins/copyfile"; tags = [ "from:oh-my-zsh" ]; } # Plugin from oh-my-zsh
    #       { name = "plugins/copypath"; tags = [ "from:oh-my-zsh" ]; } # Plugin from oh-my-zsh
    #       { name = "plugins/cp"; tags = [ "from:oh-my-zsh" ]; } # Plugin from oh-my-zsh
    #       { name = "plugins/docker"; tags = [ "from:oh-my-zsh" ]; } # Plugin from oh-my-zsh
    #       { name = "plugins/docker-compose"; tags = [ "from:oh-my-zsh" ]; } # Plugin from oh-my-zsh
    #       { name = "plugins/extract"; tags = [ "from:oh-my-zsh" ]; } # Plugin from oh-my-zsh
    #       { name = "plugins/eza"; tags = [ "from:oh-my-zsh" ]; } # Plugin from oh-my-zsh
    #       # { name = "z-shell/zsh-eza"; }
    #       { name = "plugins/fancy-ctrl-z"; tags = [ "from:oh-my-zsh" ]; } # Plugin from oh-my-zsh
    #       { name = "plugins/fzf"; tags = [ "from:oh-my-zsh" ]; } # Plugin from oh-my-zsh
    #       { name = "plugins/history"; tags = [ "from:oh-my-zsh" ]; } # Plugin from oh-my-zsh
    #       { name = "plugins/nmap"; tags = [ "from:oh-my-zsh" ]; } # Plugin from oh-my-zsh
    #       { name = "plugins/rsync"; tags = [ "from:oh-my-zsh" ]; } # Plugin from oh-my-zsh
    #       { name = "plugins/rust"; tags = [ "from:oh-my-zsh" ]; } # Plugin from oh-my-zsh
    #       { name = "plugins/screen"; tags = [ "from:oh-my-zsh" ]; } # Plugin from oh-my-zsh
    #       { name = "plugins/ssh"; tags = [ "from:oh-my-zsh" ]; } # Plugin from oh-my-zsh
    #       # { name = "plugins/thefuck"; tags = ["from:oh-my-zsh"]; } # Plugin from oh-my-zsh
    #       # { name = "plugins/vscode"; tags = ["from:oh-my-zsh"]; } # Plugin from oh-my-zsh - not working as of 2/13/25
    #       # { name = "plugins/zoxide"; tags = ["from:oh-my-zsh"]; } # Plugin from oh-my-zsh
    #       # { name = "plugins/zsh-interactive-cd"; tags = ["from:oh-my-zsh"]; } # Plugin from oh-my-zsh
    #       # { name = "plugins/pre-commit"; tags = ["from:oh-my-zsh"]; } # Plugin from oh-my-zsh; not using pre-commits yet so this is disabled
    #       # { name = "plugins/lxd"; tags = ["from:oh-my-zsh"]; } # Plugin from oh-my-zsh; not implemented because I haven't gotten home-manager working on proxmox yet
    #       # { name = "zsh-users/zsh-history-substring-search";}
    #       # { name = "zsh-users/zsh-syntax-highlighting";}
    #       # { name = "zsh-users/zsh-autosuggestions";}
    #       # { name = "zsh-users/zsh-completions";}
    #       # { name = "djui/alias-tips";}
    #       { name = "zpm-zsh/ls"; }
    #       { name = "zpm-zsh/colors"; }
    #       # { name = "zpm-zsh/dircolors-neutral";} #depreciated look for an alt
    #       # { name = "dbz/kube-aliases";}
    #       # { name = "zsh-users"; plugin = "zsh-completions"; }
    #       # { name = "zsh-users"; plugin = "zsh-syntax-highlighting"; }
    #       # { name = "zsh-users"; plugin = "zsh-history-substring-search"; }
    #       # { name = "spwhitt"; plugin = "nix-zsh-completions"; }
    #       # { name = "softmoth"; plugin = "zsh-vim-mode"; }
    #       # { name = "desyncr"; plugin = "auto-ls"; }
    #     ];
    #   };
  };

  home.packages = with pkgs; [
    # direnv
    # python3 #needed for aliases plugin from oh-my-zsh and other alias plugin
    # eza #needed for eza plugin
    # fzf #needed for fzf plugin
    # gitflow #needed for git-flow plugin
    # git-lfs #needed for git-lfs plugin
    # fortune #needed for hitchhiker plugin
    # strfile #needed for hitchhiker plugin
    # zoxide #needed for zoxide plugin
    # chroma #needed for colorize plugin from oh-my-zsh
  ];

}
