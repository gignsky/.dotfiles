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

      # Make dependencies available in PATH
      export PATH="${pkgs.lib.makeBinPath dependencies}:$PATH"

      # Execute the original script with all arguments
      exec ${pkgs.bash}/bin/bash "${scriptPath}" "$@"
    ''
    // {
      meta = {
        inherit description;
        # license = pkgs.lib.licenses.mit;
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

  # Helper function to create a packaged script from a .py file
  # Mirrors makeScriptPackage, but execs python3 and can export env vars so
  # store paths (shared libraries, for instance) can be injected at build time.
  makePythonScriptPackage =
    {
      name, # Package name (used for binary name)
      scriptPath, # Path to the .py file
      dependencies ? [ ], # List of packages this script depends on
      env ? { }, # Environment variables to export before running
      description ? "A packaged python script",
    }:
    pkgs.writeShellScriptBin name ''
      # Auto-generated wrapper for ${scriptPath}

      # Make dependencies available in PATH
      export PATH="${pkgs.lib.makeBinPath dependencies}:$PATH"
      ${pkgs.lib.concatStringsSep "\n" (
        pkgs.lib.mapAttrsToList (k: v: "export ${k}=${pkgs.lib.escapeShellArg v}") env
      )}

      # Execute the original script with all arguments
      exec ${pkgs.python3}/bin/python3 "${scriptPath}" "$@"
    ''
    // {
      meta = {
        inherit description;
        # writeShellScriptBin sets this, but the meta override above would drop
        # it and lib.getExe needs it.
        mainProgram = name;
        maintainers = [ ];
      };
      passthru = {
        inherit scriptPath dependencies;
        # Basic test that the script compiles under the python we ship
        tests.basic = pkgs.runCommand "${name}-test" { buildInputs = [ pkgs.python3 ]; } ''
          ${pkgs.python3}/bin/python3 -m py_compile "${scriptPath}" || exit 1
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
    nixos-rebuild = makeScriptPackage {
      name = "nixos-rebuild";
      scriptPath = ../scripts/nixos-rebuild.sh;
      dependencies = with pkgs; [
        bash
        nix
        # nixos-rebuild is available from system, not needed here (would cause recursion)
        hostname
      ];
      description = "Rebuilds NixOS system configuration from flake";
    };

    # Home Manager rebuild script
    home-switch = makeScriptPackage {
      name = "home-switch";
      scriptPath = ../scripts/home-switch.sh;
      dependencies = with pkgs; [
        bash
        nix
        home-manager
        hostname
      ];
      description = "Rebuilds Home Manager configuration from flake";
    };

    # # Bootstrap script
    # bootstrap-nixos = makeScriptPackage {
    #   name = "bootstrap-nixos";
    #   scriptPath = ../scripts/bootstrap-nixos.sh;
    #   dependencies = with pkgs; [
    #     bash
    #     git
    #     nix
    #     gnugrep
    #     coreutils
    #   ];
    #   description = "Bootstraps a new NixOS installation with dotfiles";
    # };

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

    # polybar: network throughput sparkline (tail-mode custom/script)
    polybar-net-graph = makeScriptPackage {
      name = "polybar-net-graph";
      scriptPath = ../scripts/polybar-net-graph.sh;
      dependencies = with pkgs; [
        bash
        coreutils
      ];
      description = "Network throughput sparkline for polybar (prints one line per second)";
    };

    # polybar: count of minimized (bspwm `hidden`) windows
    polybar-hidden-count = makeScriptPackage {
      name = "polybar-hidden-count";
      scriptPath = ../scripts/polybar-hidden-count.sh;
      dependencies = with pkgs; [
        bash
        coreutils
        bspwm
      ];
      description = "Prints how many windows are currently minimized, for polybar";
    };

    # rofi picker for restoring minimized (bspwm `hidden`) windows
    bspwm-hidden-picker = makeScriptPackage {
      name = "bspwm-hidden-picker";
      scriptPath = ../scripts/bspwm-hidden-picker.sh;
      dependencies = with pkgs; [
        bash
        coreutils
        bspwm
        xdotool
        rofi
      ];
      description = "rofi picker to restore a minimized window, by desktop/class/title";
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

    # Thunderbird credential seeder (see home/gig/common/optional/thunderbird.nix)
    # nss_latest is deliberate: it is the same NSS that thunderbird links
    # against, so the key4.db and SDR blobs we write are exactly what
    # Thunderbird expects to read back.
    seed-thunderbird-logins = makePythonScriptPackage {
      name = "seed-thunderbird-logins";
      scriptPath = ../scripts/seed-thunderbird-logins.py;
      dependencies = with pkgs; [
        coreutils
      ];
      env = {
        SEED_THUNDERBIRD_NSS_LIBDIR = "${pkgs.lib.getLib pkgs.nss_latest}/lib";
      };
      description = "Seeds a Thunderbird profile's logins.json with NSS-encrypted mail credentials";
    };

  };

in
scripts
