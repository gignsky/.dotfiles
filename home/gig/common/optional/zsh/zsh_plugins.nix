{pkgs, ...}:

with builtins;
let
  _zplug=( _group: _name : {
    name = "${_name}";
    src = builtins.fetchTarball "https://github.com/${_group}/${_name}/archive/master.tar.gz";
  });
  make_plugin = {group, name , file, ...} : {
    name = "${name}";
    src = builtins.fetchTarball "https://github.com/${group}/${name}/archive/master.tar.gz";
    file = file;
  };
in
  rec {

    zsh_plugins = {
      zsh-autosuggestions = _zplug "zsh-users" "zsh-autosuggestions";
      zsh-completions= _zplug "zsh-users" "zsh-completions";
      zsh-syntax-highlighting = _zplug "zsh-users" "zsh-syntax-highlighting";
      zsh-history-substring-search = _zplug "zsh-users" "zsh-history-substring-search";
      powerlevel10k = make_plugin { group = "romkatv"; name = "powerlevel10k"; file = "powerlevel10k.zsh-theme";};
      nix-zsh-completions = _zplug "spwhitt" "nix-zsh-completions";
      zsh-vim-mode = _zplug "softmoth" "zsh-vim-mode";
      desyncr-auto-ls = _zplug "desyncr" "auto-ls";
    };
    plugin_list = builtins.attrValues zsh_plugins;
  }
