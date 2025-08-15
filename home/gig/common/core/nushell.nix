{
  pkgs,
  inputs,
  outputs,
  system,
  ...
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
      package = pkgs.nushell;
      shellAliases = import ../optional/shellAliases.nix;
      settings = {
        show_banner = false;
        completions.external = {
          enable = true;
          max_results = 200;
        };
        buffer_editor = "${inputs.gigvim.packages.${system}.gigvim}/bin/nvim";
      };
      environmentVariables = {
        EDITOR = "${inputs.gigvim.packages.${system}.gigvim}/bin/nvim";
      };
      plugins = with pkgs.nushellPlugins; [
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

        # Direnv integration
        $env.config = ($env.config? | default {})
        $env.config.hooks = ($env.config.hooks? | default {})
        $env.config.hooks.pre_prompt = (
            $env.config.hooks.pre_prompt?
            | default []
            | append {||
                let direnv_output = (direnv export json | from json --strict | default {})
                if ($direnv_output | is-not-empty) {
                    $direnv_output | load-env
                }
            }
        )
      '';
    };
    zoxide = {
      enable = true;
      enableNushellIntegration = true;
    };

    carapace = {
      enable = true;
      package = pkgs.unstable.carapace;
      enableNushellIntegration = true;
    };
  };
}
