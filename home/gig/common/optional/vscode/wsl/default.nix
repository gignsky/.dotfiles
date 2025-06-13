{ ... }:

{
  # Debug line to check if this file is being accessed
  _debug = builtins.trace "Accessing /home/gig/.dotfiles/home/gig/common/optional/vscode/wsl/default.nix" null;

  # imports = (configLib.scanPaths ./.);
}
