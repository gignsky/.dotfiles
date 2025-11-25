{
  pkgs,
  ...
}:
pkgs.mkShell {
  NIX_CONFIG = "extra-experimental-features = nix-command flakes ";

  # Don't auto-include pre-commit packages - manual setup like spacedock

  nativeBuildInputs = builtins.attrValues {
    inherit (pkgs)
      git
      pre-commit # Manual pre-commit setup
      lolcat
      nixfmt-rfc-style
      nil
      age
      ssh-to-age
      sops
      home-manager
      just
      lazygit
      statix
      deadnix
      nix
      fzf
      #unstable packages
      # unstable.statix
      # personal packages
      quick-results
      upjust
      upflake
      upspell
      #necessary for bootstrapping
      ripgrep
      ;
  };

  shellHook = ''
    # Command to ensure the .pre-commit-config.yaml is set up 
    # by the 'pre-commit' package, which should be in nativeBuildInputs.
    if [ ! -f .pre-commit-config.yaml ]; then
      echo "Setting up pre-commit hooks..."
      # Clear hooksPath to allow pre-commit installation 
      ${pkgs.git}/bin/git config --unset-all core.hooksPath 2>/dev/null || true
      ${pkgs.pre-commit}/bin/pre-commit install --install-hooks
    fi

    echo "Welcome to the dotfiles devShell" | ${pkgs.lolcat}/bin/lolcat
    echo "Note: Pre-commit hooks are available but not part of flake check"
  '';
}
