{ pkgs, ... }: {
  programs.nushell = {
    enable = true;
    # package = "${pkgs.nushell}/bin/nu";
    shellAliases = import ./shellAliases.nix;
    settings = {
      show_banner = false;
      completions.external = {
        enable = true;
        max_results = 200;
      };
      buffer_editor = "vi";
    };
    plugins = with pkgs.nushellPlugins; [
      net
      highlight
      units
      formats
      query
    ];
  };
  programs.zoxide = {
    enable = true;
    enableNushellIntegration = true;
  };
}
