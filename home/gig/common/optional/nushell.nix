_: {
  programs.nushell = {
    enable = true;
    # package = "${pkgs.nushell}/bin/nu";
    shellAliases = import ./shellAliases.nix;
  };
}
