{
  pkgs,
  inputs,
  outputs,
  lib,
  configLib,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) system;

  # The path to the custom NuShell resource files, relative to this module.
  nuResourcesPath = configLib.relativeToRoot "home/gig/common/resources/nushell";

  # Utilizes the provided configLib.scanPaths function to read all .nu files
  # in the directory and concatenate their contents into a single string.
  customNuFunctions = lib.scanPathsNuShell nuResourcesPath;

  # Fleet topology for `als stats --fleet`. Reachability lives in vars/fleet.nix,
  # activity in vars/hosts.nix — als.nu itself hardcodes no hosts, so the module
  # stays portable enough to extract upstream.
  hostActive = import (configLib.relativeToRoot "vars/hosts.nix");
  fleetTargets = import (configLib.relativeToRoot "vars/fleet.nix");
  alsFleet = lib.mapAttrsToList (name: spec: {
    inherit name;
    inherit (spec) target;
    remote = spec.remote or "nu -l -c 'als stats --json'";
    enabled = hostActive.${name} or true;
  }) fleetTargets;

  # Carapace's nushell bridge, patched for the completer API change in nushell
  # 0.116: completers now get a record and `{|spans|}` triggers a deprecation
  # warning on every Tab. The login shell (pkgs.unstable.nushell) and HM's
  # nushell (pkgs.nushell) can differ in version but share this config.nu, so
  # the closure takes `place` and accepts both shapes: a record whose
  # `place.command` is the token list (>= 0.116), or the bare spans list
  # passed positionally (older). The grep fails the build if upstream changes
  # the closure header, so this patch can't silently stop applying.
  carapaceNuConfig = pkgs.runCommand "carapace-nushell-config.nu" { } ''
    ${lib.getExe pkgs.carapace} _carapace nushell \
      | sed 's|"/homeless-shelter|$"($env.HOME)|g' > raw.nu
    grep -q 'let carapace_completer = {|spans|' raw.nu
    sed 's/let carapace_completer = {|spans|/let carapace_completer = {|place|\n  let spans = (if ($place | describe | str starts-with "list") { $place } else { $place.command })/' \
      raw.nu > "$out"
  '';
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
      package = pkgs.nushell;
      shellAliases = import ../optional/shellAliases.nix;
      settings = {
        show_banner = false;
        completions.external = {
          enable = true;
          max_results = 200;
        };
        buffer_editor = "${inputs.nixpkgs.packages.${system}.gigvim}/bin/nvim";
      };
      environmentVariables = {
        EDITOR = "${inputs.nixpkgs.packages.${system}.gigvim}/bin/nvim";
      };
      plugins = with pkgs.nushellPlugins; [
        # net - currently marked as broken
        # highlight - temp disabled to be brought back in 26.05
        # units - currently marked as broken
        formats
        query
        gstat
        polars
      ];
      extraConfig = ''
        overlay use ${inputs.git-aliases}/git-aliases.nu

        source ${carapaceNuConfig}

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

        # als: fleet topology (data only — als.nu never hardcodes hosts)
        $env.ALS_FLEET = (r#'${builtins.toJSON alsFleet}'# | from json)

        # ┌──────────────────────────────────────────────────────────┐
        # │ Custom Functions Loaded from Resource Directory          │
        # │ Sourced via configLib.scanPaths for modular NuShell code.│
        # └──────────────────────────────────────────────────────────┘
        ${customNuFunctions}

        # als: show the shorter alias when the long form is typed.
        # Appended rather than assigned so it composes with any other hook.
        # `try` without `catch` swallows errors — a hint must never be able to
        # wedge the shell or eat a command.
        $env.config.hooks.pre_execution = (
            $env.config.hooks.pre_execution?
            | default []
            | append {|| try { als hint-line (commandline) } }
        )
      '';
    };
    zoxide = {
      enable = true;
      enableNushellIntegration = true;
    };

    carapace = {
      enable = true;
      package = pkgs.carapace;
      # Sourced via carapaceNuConfig in nushell.extraConfig instead, see there.
      enableNushellIntegration = false;
    };
  };
}
