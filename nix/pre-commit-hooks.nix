{
  inputs,
  system,
  ...
}:
{
  # Shared pre-commit hook configuration
  mkPreCommitCheck =
    src:
    inputs.pre-commit-hooks.lib.${system}.run {
      inherit src;
      hooks = {
        nixfmt-rfc-style = {
          enable = true;
          excludes = [ ".*hardware-configuration\\.nix$" ];
        };
        statix = {
          enable = false; # Disable for now, use standalone pre-commit instead
        };
        deadnix = {
          enable = true;
          excludes = [
            "home/gig/common/optional/starship.nix"
            "hosts/common/users/gig/default.nix"
          ];
        };
        shellcheck = {
          enable = false; # Disable for now, focus on Nix linting
        };
        markdownlint = {
          enable = false;
        };
        yamllint = {
          enable = true;
          excludes = [ ".github/workflows/flake-check.yml" ];
        };
        end-of-file-fixer = {
          enable = true;
          excludes = [ ".*hardware-configuration\\.nix$" ];
        };
      };
    };
}
