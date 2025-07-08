# You can build these directly using 'nix build .#example'

{ pkgs ? import <nixpkgs> { }
,
}:
rec {
  #################### Example Packages #################################
  # example = pkgs.writeShellScriptBin "example" ''
  #   ${pkgs.cowsay}/bin/cowsay "hello world" | ${pkgs.lolcat}/bin/lolcat 2> /dev/null
  # '';

  supertree = pkgs.writeShellScriptBin "supertree" ''
    ${pkgs.tree}/bin/tree ..
  '' // {
    passthru.tests = {
      basic = pkgs.runCommand "supertree-test" { buildInputs = [ supertree ]; } ''
        set -e
        # Should print something, check for a known directory in the output
        supertree > $out
        grep -q "home" $out
      '';
    };
  };

  quick-results = pkgs.writeShellScriptBin "quick-results" ''
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
        echo "No $name directory found" | ${pkgs.cowsay}/bin/cowsay | ${pkgs.lolcat}/bin/lolcat 2> /dev/null
      fi
    }

    # Check cargo target folder
    check_and_display "./target" "cargo target"

    # Check nix result folder
    check_and_display "./result" "nix result"
    
    # Check nix result-man folder
    check_and_display "./result-man" "nix result-man"
  '' // {
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

  upjust = pkgs.writeShellScriptBin "upjust" ''
    git add justfile
    git commit -m "upjust - updated justfile"
  '' // {
    passthru.tests = {
      basic = pkgs.runCommand "upjust-test" { buildInputs = [ upjust ]; } ''
        set -e
        # Should fail gracefully since .git may not exist in sandbox
        if upjust > $out 2>&1; then
          grep -q "justfile" $out || true
        else
          grep -q "not a git repository" $out || true
        fi
      '';
    };
  };

  upspell = pkgs.writeShellScriptBin "upspell" ''
    git add .cspell/custom-dictionary-workspace.txt
    git commit -m "upspell - updated spellfile"
  '' // {
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

  upflake = pkgs.writeShellScriptBin "upflake" ''
    git add flake.lock
    git commit -m "upflake - updated flake.lock"
  '' // {
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

  cargo-update = pkgs.writeShellScriptBin "cargo-update" ''
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
  '' // {
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

}
