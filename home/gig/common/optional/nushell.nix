{ pkgs
, inputs
, ...
}: {
  imports = [
    ./starship.nix
  ];
  programs = {
    nushell = {
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
        gstat
        polars
      ];
      extraConfig = ''
        overlay use ${inputs.git-aliases}/git-aliases.nu
      '';
    };
    zoxide = {
      enable = true;
      enableNushellIntegration = true;
    };
    direnv.enableNushellIntegration = true;
    carapace = {
      enable = false;
      enableNushellIntegration = true;
    };
  };
}
