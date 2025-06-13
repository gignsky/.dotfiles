{ enable ? true }:

# Nix-related VS Code extensions
if enable then [
  "arrterian.nix-env-selector"
  "bbenoist.nix"
  "brettm12345.nixfmt-vscode"
  "jnoortheen.nix-ide"
  "mkhl.direnv"
  "nefrob.vscode-just-syntax"
  "pinage404.nix-extension-pack"
  "skellock.just"
] else [ ]
