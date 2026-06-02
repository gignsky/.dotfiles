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

    # Roll Flow workflow manager for NixOS multi-host configurations
    roll-flow = pkgs.stdenv.mkDerivation {
      pname = "roll-flow";
      version = "1.0.0";

      src = ../scripts/roll-flow;
      dontUnpack = true;

      nativeBuildInputs = [ pkgs.makeWrapper ];

      installPhase = ''
                mkdir -p $out/bin
                mkdir -p $out/share/nu/completions
                
                # Create wrapper script
                cat > $out/bin/roll-flow <<'WRAPPER'
        #!/bin/sh
        exec ${pkgs.nushell}/bin/nu SCRIPT_PATH "$@"
        WRAPPER
                
                sed -i "s|SCRIPT_PATH|$src|g" $out/bin/roll-flow
                chmod +x $out/bin/roll-flow
                
                # Wrap with dependencies in PATH
                wrapProgram $out/bin/roll-flow \
                  --prefix PATH : ${
                    pkgs.lib.makeBinPath (
                      with pkgs;
                      [
                        nushell
                        git
                        nix
                      ]
                    )
                  }
                
                # Create Nushell completion file
                cat > $out/share/nu/completions/roll-flow.nu <<'EOF'
        export extern "rf" [
          command?: string@"nu-complete rf commands"
          --help(-h)
        ]
        export extern "rf init" [
          --rolling-branch(-r): string
          --stable-branch(-s): string
          --roll-prefix(-p): string
          --username(-u): string
          --hosts(-h): string
        ]
        export extern "rf start" [ theme: string ]
        export extern "rf integrate" [ branch: string@"nu-complete git branches" ]
        export extern "rf graduate" [
          roll?: string@"nu-complete rf rolls"
          --promote
          --all
          --quasi
        ]
        export extern "rf promote" [ roll?: string@"nu-complete rf rolls" ]
        export extern "rf status" []
        export extern "rf test-all" []
        export extern "rf list" []
        def "nu-complete rf commands" [] {
          ["init" "start" "integrate" "graduate" "promote" "status" "test-all" "list"]
        }
        def "nu-complete git branches" [] {
          git branch --list | lines | str trim | str replace "* " ""
        }
        def "nu-complete rf rolls" [] {
          git branch --list "roll/*" | lines | str trim | str replace "* " ""
        }
        EOF
      '';

      meta = {
        description = "Git workflow manager for NixOS multi-host dotfiles (Roll Flow system)";
        mainProgram = "roll-flow";
      };

      passthru = {
        scriptPath = ../scripts/roll-flow;
        dependencies = with pkgs; [
          nushell
          git
          nix
        ];
      };
    };
  };

in
scripts
// {
  # Short alias 'rf' wraps the full 'roll-flow' command
  rf = pkgs.writeShellScriptBin "rf" ''
    # Wrapper that calls roll-flow with all arguments
    exec ${scripts.roll-flow}/bin/roll-flow "$@"
  '';
}
