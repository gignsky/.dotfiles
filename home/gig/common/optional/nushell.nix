{ pkgs
, inputs
, outputs
, system
, ...
}:
{
  # overlays
  nixpkgs.overlays = [
    outputs.overlays.unstable-packages
    # outputs.overlays.wrap-packages # example for overlays
  ];
  imports = [
    ./starship.nix
  ];
  programs = {
    nushell = {
      enable = true;
      package = pkgs.unstable.nushell;
      shellAliases = import ./shellAliases.nix;
      settings = {
        show_banner = false;
        completions.external = {
          enable = true;
          max_results = 200;
        };
        buffer_editor = "${inputs.gigvim.packages.${system}.full}/bin/nvim";
      };
      plugins = with pkgs.unstable.nushellPlugins; [
        # net - currently marked as broken
        highlight
        # units - currently marked as broken
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
      enable = true;
      enableNushellIntegration = true;
    };
  };
}
