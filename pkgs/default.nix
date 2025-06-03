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
  '';

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
  '';

  upjust = pkgs.writeShellScriptBin "upjust" ''
    git add justfile
    git commit -m "upjust - updated justfile"
  '';

  upspell = pkgs.writeShellScriptBin "upjust" ''
    git add .cspell/custom-dictionary-workspace.txt
    git commit -m "upspell - updated spellfile"
  '';

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
  '';

  #################### Packages with external source ####################
  # zsh-als-aliases = pkgs.callPackage ./zsh-als-aliases { }; # Removed as unneccecary but left for help in the future

}
