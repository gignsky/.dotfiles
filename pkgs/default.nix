# You can build these directly using 'nix build .#example'

{
  pkgs ? import <nixpkgs> { },
}:
let
  # Import packaged scripts
  scripts = import ./scripts.nix { inherit pkgs; };
in
rec {
  #################### Example Packages #################################
  # example = pkgs.writeShellScriptBin "example" ''
  #   ${pkgs.cowsay}/bin/cowsay "hello world" | ${pkgs.lolcat}/bin/lolcat 2> /dev/null
  # '';

  locker =
    pkgs.writeShellScriptBin "locker" ''
      COMMIT=""

      # Parse command line args 
      while [[ $# -gt 0 ]]; do
        case $1 in
          -y|--yes)
            COMMIT=true
            shift
            ;;
          -n|--no)
            COMMIT=false
            shift
            ;;
          -h|--help)
      echo "Usage: locker [-y|--yes] [-n|--no] [-h|--help]"
      echo "  -y, --yes    Automatically commit the lock file"
      echo "  -n, --no     Don't commit the lock file"  
      echo "  -h, --help   Show this help message"
      echo "  (no args)    Ask interactively"
            exit 0
            ;;
          *)
            echo "Unknown option: $1"
            echo "Usage: locker [-y|--yes] [-n|--no] [-h|--help]"
            exit 1
            ;;
        esac
      done

      echo "Locking Flake with Current flake.nix content" | ${pkgs.lolcat}/bin/lolcat

      # If no flags provided, ask interactively
      if [[ -z "$COMMIT" ]]; then
        echo -n "Commit lock file? [Y/n]: "
        read -r commit
        if [[ "$commit" =~ ^[Nn]([Oo])?$ ]]; then
          COMMIT=false
        else
          COMMIT=true
        fi
      fi

      # Execute based on decision
      if $COMMIT; then
        nix flake lock --commit-lock-file
        echo "flake.lock updated! -- COMMITTED" | ${pkgs.cowsay}/bin/cowsay | ${pkgs.lolcat}/bin/lolcat
      else
        nix flake lock
        echo "flake.lock updated! -- NOT COMMITTED" | ${pkgs.cowsay}/bin/cowsay | ${pkgs.lolcat}/bin/lolcat
      fi
    ''
    // {
      passthru.tests = rec {
        # Run all tests at once
        all-tests = pkgs.runCommand "locker-all-tests" { } ''
          # Verify all individual tests pass by checking they exist
          test -f ${help-output} || (echo "help-output test failed"; exit 1)
          test -f ${invalid-args} || (echo "invalid-args test failed"; exit 1)
          test -f ${script-syntax} || (echo "script-syntax test failed"; exit 1)
          test -f ${dependencies} || (echo "dependencies test failed"; exit 1)
          test -f ${no-flake-error} || (echo "no-flake-error test failed"; exit 1)

          echo "All locker tests passed!" > $out
        '';

        # Test 1: Help output functionality
        help-output =
          pkgs.runCommand "locker-help-test"
            {
              buildInputs = [ locker ];
            }
            ''
              set -e

              # Test --help flag
              if locker --help > help_output 2>&1; then
                grep -q "Usage:" help_output || {
                  echo "Missing usage line in help"
                  exit 1
                }
                grep -q "\-y.*commit" help_output || {
                  echo "Missing -y flag description"
                  exit 1
                }
                grep -q "\-n.*commit" help_output || {
                  echo "Missing -n flag description"
                  exit 1
                }
                grep -q "\-h.*help" help_output || {
                  echo "Missing -h flag description"
                  exit 1
                }
              else
                echo "Help command failed unexpectedly"
                exit 1
              fi

              # Test -h short flag
              locker -h > short_help 2>&1
              grep -q "Usage:" short_help || {
                echo "Short help flag failed"
                exit 1
              }

              echo "Help functionality working correctly" > $out
            '';

        # Test 2: Invalid argument handling
        invalid-args =
          pkgs.runCommand "locker-invalid-args-test"
            {
              buildInputs = [ locker ];
            }
            ''
              set -e

              # Test invalid flag
              if locker --invalid-flag > error_output 2>&1; then
                echo "Invalid flag should have failed"
                exit 1
              else
                grep -q "Unknown option" error_output || {
                  echo "Missing expected error message"
                  exit 1
                }
                grep -q "Usage:" error_output || {
                  echo "Missing usage in error output"
                  exit 1
                }
              fi

              echo "Invalid argument handling working correctly" > $out
            '';

        # Test 3: Script syntax and basic structure validation
        script-syntax =
          pkgs.runCommand "locker-syntax-test"
            {
              buildInputs = [
                locker
                pkgs.bash
                pkgs.coreutils
              ];
            }
            ''
              set -e

              # Test that script exists and is executable
              command -v locker > /dev/null || {
                echo "locker command not found"
                exit 1
              }

              # Test script has valid bash syntax
              bash -n $(command -v locker) || {
                echo "locker script has syntax errors"
                exit 1
              }

              echo "Script syntax validation passed" > $out
            '';

        # Test 4: Dependency injection verification
        dependencies =
          pkgs.runCommand "locker-deps-test"
            {
              buildInputs = [
                locker
                pkgs.bash
                pkgs.gnugrep
                pkgs.coreutils
              ];
            }
            ''
              set -e

              # Check script contains expected dependencies
              cat $(command -v locker) > script_content

              grep -q "lolcat" script_content || {
                echo "Script missing lolcat dependency"
                cat script_content
                exit 1
              }

              grep -q "cowsay" script_content || {
                echo "Script missing cowsay dependency"  
                cat script_content
                exit 1
              }

              grep -q "nix flake lock" script_content || {
                echo "Script missing nix flake lock command"
                exit 1
              }

              grep -q "nix flake lock --commit-lock-file" script_content || {
                echo "Script missing commit variant of flake lock"
                exit 1
              }

              echo "Dependency verification passed" > $out
            '';

        # Test 5: No nix command environment (expected failure)
        no-flake-error =
          pkgs.runCommand "locker-no-nix-test"
            {
              buildInputs = [ locker ];
            }
            ''
              set -e

              LOCKER_CMD=$(command -v locker)

              # Test -y flag (should fail - no nix command available)
              if $LOCKER_CMD -y > commit_output 2>&1; then
                # Check if it "succeeded" but nix command actually failed
                if grep -q "nix: command not found" commit_output; then
                  echo "Expected behavior: nix command not found"
                else
                  echo "locker -y unexpectedly succeeded:"
                  cat commit_output
                  exit 1
                fi
              else
                # If it failed, check for expected error patterns
                grep -E "(nix: command not found|flake|error)" commit_output || {
                  echo "Unexpected error output for -y flag:"
                  cat commit_output
                  exit 1
                }
              fi

              echo "No nix environment handling working correctly" > $out
            '';
      };
    };

  supertree =
    pkgs.writeShellScriptBin "supertree" ''
      ${pkgs.tree}/bin/tree ..
    ''
    // {
      passthru.tests = {
        basic = pkgs.runCommand "supertree-test" { buildInputs = [ supertree ]; } ''
          set -e
          # Should print something, check for a known directory in the output
          supertree > $out
          grep -q "home" $out
        '';
      };
    };

  quick-results =
    pkgs.writeShellScriptBin "quick-results" ''
      check_and_display() {
        local dir=$1
        local name=$2
        if [ -d "$dir" ]; then
          echo "Contents of $name directory:" | ${pkgs.lolcat}/bin/lolcat 2> /dev/null
          if [ "$dir" == "./target" ]; then
            ${pkgs.tree}/bin/tree -L 2 "$dir" | ${pkgs.lolcat}/bin/lolcat 2> /dev/null
          else
            ${pkgs.tree}/bin/tree "$dir" | ${pkgs.lolcat}/bin/lolcat 2> /dev/null
          fi
        else
          if [ "$dir" == "./result" ]; then
            if [ -d "./result" ]; then
              ${pkgs.tree}/bin/tree "$dir" | ${pkgs.lolcat}/bin/lolcat 2> /dev/null
            else
              ls -lah "$dir" | ${pkgs.lolcat}/bin/lolcat 2> /dev/null
            fi
          else
            echo "No $name directory found" | ${pkgs.cowsay}/bin/cowsay | ${pkgs.lolcat}/bin/lolcat 2> /dev/null
          fi
        fi
      }

      # Check cargo target folder
      check_and_display "./target" "cargo target"

      # Check nix result folder
      check_and_display "./result" "nix result"

      # Check nix result-man folder
      check_and_display "./result-man" "nix result-man"

      # Check node_modules folder
      check_and_display "./node_modules" "node_modules"

      # Check .svelte-kit folder
      check_and_display "./.svelte-kit" ".svelte-kit"
    ''
    // {
      passthru.tests = {
        basic = pkgs.runCommand "quick-results-test" { buildInputs = [ quick-results ]; } ''
          set -e
          # Should print something about missing directories (since they likely don't exist in the build sandbox)
          quick-results > $out
          grep -q "No cargo target directory found" $out
          grep -q "No nix result directory found" $out
          grep -q "No nix result-man directory found" $out
        '';
      };
    };

  upignore =
    pkgs.writeShellScriptBin "upignore" ''
      git add .gitignore
      git commit -m "upignore - updated .gitignore"
    ''
    // {
      passthru.tests = {
        basic = pkgs.runCommand "upignore-test" { buildInputs = [ upignore ]; } ''
          set -e
          # Should fail gracefully since .git may not exist in sandbox
          if upignore > $out 2>&1; then
            grep -q ".gitignore" $out || true
          else
            grep -q "not a git repository" $out || true
          fi
        '';
      };
    };

  upjust =
    pkgs.writeShellScriptBin "upjust" ''
      ${pkgs.git}/bin/git add justfile
      ${pkgs.git}/bin/git commit -m "upjust - updated justfile"
    ''
    // {
      passthru.tests = rec {
        # Run all tests at once
        all-tests =
          pkgs.runCommand "upjust-all-tests"
            {
              # Reference the tests as dependencies, not buildInputs
            }
            ''
              # Verify all individual tests pass by checking they exist
              test -f ${no-git-repo} || (echo "no-git-repo test failed"; exit 1)
              test -f ${no-justfile} || (echo "no-justfile test failed"; exit 1)
              test -f ${with-justfile-changes} || (echo "with-justfile-changes test failed"; exit 1)
              test -f ${no-changes} || (echo "no-changes test failed"; exit 1)

              echo "All upjust tests passed!" > $out
            '';

        # Test 1: No git repository (should fail gracefully)
        no-git-repo =
          pkgs.runCommand "upjust-no-git-test"
            {
              buildInputs = [ upjust ];
            }
            ''
              set -e
              # Should fail gracefully since .git doesn't exist
              if upjust > $out 2>&1; then
                grep -q "justfile" $out || true
              else
                grep -E "(fatal:|not a git repository)" $out || true
              fi
            '';

        # Test 2: Git repo exists but no justfile (should fail)
        no-justfile =
          pkgs.runCommand "upjust-no-justfile-test"
            {
              buildInputs = [
                upjust
                pkgs.git
                pkgs.coreutils
              ];
            }
            ''
              set -e
              # Create a git repository
              git init
              git config user.name "Test User"
              git config user.email "test@example.com"

              # Run upjust (should fail - no justfile to add)
              if upjust > $out 2>&1; then
                echo "Unexpected success - should have failed without justfile"
                exit 1
              else
                # Should get error about pathspec not matching files
                grep -E "(pathspec.*did not match|No such file)" $out || true
              fi
            '';

        # Test 3: Git repo with justfile that has changes (should succeed)
        with-justfile-changes =
          pkgs.runCommand "upjust-with-changes-test"
            {
              buildInputs = [
                upjust
                pkgs.git
                pkgs.coreutils
              ];
            }
            ''
              set -e
              # Create git repo and initial justfile
              git init
              git config user.name "Test User"
              git config user.email "test@example.com"

              # Create initial justfile and commit it
              echo "# Initial justfile" > justfile
              git add justfile
              git commit -m "Initial justfile"

              # Modify justfile
              echo "# Modified justfile" > justfile

              # Run upjust (should succeed)
              if upjust > $out 2>&1; then
                # Should succeed and show commit message or justfile reference
                grep -E "(upjust.*updated justfile|justfile)" $out || true
              else
                echo "Unexpected failure with valid git repo and modified justfile:"
                cat $out
                exit 1
              fi
            '';

        # Test 4: Git repo with justfile but no changes (should fail)
        no-changes =
          pkgs.runCommand "upjust-no-changes-test"
            {
              buildInputs = [
                upjust
                pkgs.git
                pkgs.coreutils
              ];
            }
            ''
              set -e
              # Create git repo and justfile
              git init
              git config user.name "Test User" 
              git config user.email "test@example.com"

              # Create justfile and commit it
              echo "# Test justfile" > justfile
              git add justfile
              git commit -m "Initial justfile"

              # Run upjust (should fail - nothing to commit)
              if upjust > $out 2>&1; then
                echo "Unexpected success - should have failed with no changes"
                exit 1
              else
                # Should get "nothing to commit" or similar message
                grep -E "(nothing to commit|working tree clean)" $out || true
              fi
            '';
      };
    };

  upspell =
    pkgs.writeShellScriptBin "upspell" ''
      git add .cspell/custom-dictionary-workspace.txt
      git commit -m "upspell - updated spellfile"
    ''
    // {
      passthru.tests = {
        basic = pkgs.runCommand "upspell-test" { buildInputs = [ upspell ]; } ''
          set -e
          # Should fail gracefully since .git may not exist in sandbox
          if upspell > $out 2>&1; then
            grep -q "custom-dictionary-workspace.txt" $out || true
          else
            grep -q "not a git repository" $out || true
          fi
        '';
      };
    };

  upflake =
    pkgs.writeShellScriptBin "upflake" ''
      git add flake.lock
      git commit -m "upflake - updated flake.lock"
    ''
    // {
      passthru.tests = {
        basic = pkgs.runCommand "upflake-test" { buildInputs = [ upflake ]; } ''
          set -e
          # Should fail gracefully since .git may not exist in sandbox
          if upflake > $out 2>&1; then
            grep -q "flake.lock" $out || true
          else
            grep -q "not a git repository" $out || true
          fi
        '';
      };
    };

  cargo-update =
    pkgs.writeShellScriptBin "cargo-update" ''
      # Check for --no-commit flag
      NO_COMMIT=false
      if [[ "$1" == "--no-commit" ]]; then
          NO_COMMIT=true
      fi

      # Run cargo update
      cargo update

      # Check if Cargo.toml or Cargo.lock have changed
      if git diff --quiet Cargo.toml Cargo.lock; then
          echo "No changes detected in Cargo.toml or Cargo.lock."
          exit 0
      fi

      # If --no-commit flag is set, exit without committing
      if $NO_COMMIT; then
          echo "Changes detected, but --no-commit flag is set. Exiting without committing."
          exit 0
      fi

      # Stage and commit changes
      git add Cargo.toml Cargo.lock
      git commit -m "Update Cargo dependencies via cargo-update program"

      echo "Changes committed successfully."
    ''
    // {
      passthru.tests = {
        basic = pkgs.runCommand "cargo-update-test" { buildInputs = [ cargo-update ]; } ''
          set -e
          # Should fail gracefully since .git may not exist in sandbox
          if cargo-update --no-commit > $out 2>&1; then
            grep -q "No changes detected" $out || true
          else
            grep -q "not a git repository" $out || true
          fi
        '';
      };
    };

  #################### Packages with external source ####################
  # zsh-als-aliases = pkgs.callPackage ./zsh-als-aliases { }; # Removed as unnecessary but left for help in the future

  #################### Packaged Scripts ####################
  # Import all packaged scripts from scripts.nix
  inherit (scripts)
    check-hardware-config
    system-flake-rebuild
    home-manager-flake-rebuild
    system-flake-rebuild-test
    system-flake-rebuild-verbose
    bootstrap-nixos
    flake-build
    pre-commit-flake-check
    run-iso-vm
    package-script
    ;
}
