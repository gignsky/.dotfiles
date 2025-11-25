# Script packaging utilities
# Converts shell scripts to proper Nix packages with dependency injection

{
  pkgs ? import <nixpkgs> { },
}:

let
  # Helper function to create a packaged script from a .sh file
  makeScriptPackage =
    {
      name, # Package name (used for binary name)
      scriptPath, # Path to the .sh file
      dependencies ? [ ], # List of packages this script depends on
      description ? "A packaged shell script",
    }:
    pkgs.writeShellScriptBin name ''
      # Auto-generated wrapper for ${scriptPath}
      # Dependencies: ${builtins.concatStringsSep ", " (map (pkg: pkg.name or "unknown") dependencies)}

      # Make dependencies available in PATH
      export PATH="${pkgs.lib.makeBinPath dependencies}:$PATH"

      # Execute the original script with all arguments
      exec ${pkgs.bash}/bin/bash "${scriptPath}" "$@"
    ''
    // {
      meta = {
        inherit description;
        license = pkgs.lib.licenses.mit;
        maintainers = [ ];
      };
      passthru = {
        inherit scriptPath dependencies;
        # Basic test that the script can be executed
        tests.basic = pkgs.runCommand "${name}-test" { buildInputs = [ pkgs.bash ]; } ''
          # Test that the script is executable and has valid bash syntax
          ${pkgs.bash}/bin/bash -n "${scriptPath}" || exit 1
          echo "Script syntax check passed" > $out
        '';
      };
    };

  # Script definitions
  scripts = {
    # Hardware configuration validation script
    check-hardware-config = makeScriptPackage {
      name = "check-hardware-config";
      scriptPath = ../scripts/check-hardware-config.sh;
      dependencies = with pkgs; [
        bash
        git
        nix
        coreutils
        gnugrep
        gawk
      ];
      description = "Validates hardware configuration synchronization and GPU setup";
    };

    # Pre-commit script
    pre-commit-flake-check = makeScriptPackage {
      name = "pre-commit-flake-check";
      scriptPath = ../scripts/pre-commit-flake-check.sh;
      dependencies = with pkgs; [
        bash
        nix
        pre-commit
      ];
      description = "Runs pre-commit checks on the flake";
    };

    # Interactive script packager with fzf selection and OpenCode integration
    package-script = makeScriptPackage {
      name = "package-script";
      scriptPath = ../scripts/package-script.sh;
      dependencies = with pkgs; [
        bash
        nix
        git
        fzf
        gnugrep
        gawk
        gnused
        coreutils
        findutils
        bat
      ];
      description = "Interactive script packager with fzf selection and OpenCode test generation";
    };
  };

in
scripts
