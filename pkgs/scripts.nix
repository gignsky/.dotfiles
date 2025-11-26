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

    # System rebuild script
    system-flake-rebuild = makeScriptPackage {
      name = "system-flake-rebuild";
      scriptPath = ../scripts/system-flake-rebuild.sh;
      dependencies = with pkgs; [
        bash
        nix
        nixos-rebuild
        hostname
      ];
      description = "Rebuilds NixOS system configuration from flake";
    };

    # Home Manager rebuild script
    home-manager-flake-rebuild = makeScriptPackage {
      name = "home-manager-flake-rebuild";
      scriptPath = ../scripts/home-manager-flake-rebuild.sh;
      dependencies = with pkgs; [
        bash
        nix
        home-manager
        hostname
      ];
      description = "Rebuilds Home Manager configuration from flake";
    };

    # Test rebuild script
    system-flake-rebuild-test = makeScriptPackage {
      name = "system-flake-rebuild-test";
      scriptPath = ../scripts/system-flake-rebuild-test.sh;
      dependencies = with pkgs; [
        bash
        nix
        nixos-rebuild
        hostname
      ];
      description = "Test builds NixOS system configuration without activation";
    };

    # Verbose rebuild script
    system-flake-rebuild-verbose = makeScriptPackage {
      name = "system-flake-rebuild-verbose";
      scriptPath = ../scripts/system-flake-rebuild-verbose.sh;
      dependencies = with pkgs; [
        bash
        nix
        nixos-rebuild
        hostname
      ];
      description = "Rebuilds NixOS system with verbose output for debugging";
    };

    # Bootstrap script
    bootstrap-nixos = makeScriptPackage {
      name = "bootstrap-nixos";
      scriptPath = ../scripts/bootstrap-nixos.sh;
      dependencies = with pkgs; [
        bash
        git
        nix
        gnugrep
        coreutils
      ];
      description = "Bootstraps a new NixOS installation with dotfiles";
    };

    # Flake build script
    flake-build = makeScriptPackage {
      name = "flake-build";
      scriptPath = ../scripts/flake-build.sh;
      dependencies = with pkgs; [
        bash
        nix
      ];
      description = "Builds specific flake targets with proper error handling";
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

    # ISO VM runner
    run-iso-vm = makeScriptPackage {
      name = "run-iso-vm";
      scriptPath = ../scripts/run-iso-vm.sh;
      dependencies = with pkgs; [
        bash
        nix
        qemu
      ];
      description = "Runs the ISO installer in a VM for testing";
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
