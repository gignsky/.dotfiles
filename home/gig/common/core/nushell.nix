{
  pkgs,
  inputs,
  outputs,
  configLib,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) system;

  # The path to the custom NuShell resource files, relative to this module.
  nuResourcesPath = configLib.relativeToRoot "home/gig/common/resources/nushell";

  # Utilizes the provided configLib.scanPaths function to read all .nu files
  # in the directory and concatenate their contents into a single string.
  customNuFunctions = configLib.scanPathsNuShell nuResourcesPath;
in
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

        # ┌──────────────────────────────────────────────────────────┐
        # │ Custom Functions Loaded from Resource Directory          │
        # │ Sourced via configLib.scanPaths for modular NuShell code.│
        # └──────────────────────────────────────────────────────────┘
        ${customNuFunctions}
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
