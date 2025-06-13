{ rust ? true, python ? true, nix ? true }:

let
  rustExts = import ./rust.nix { enable = rust; };
  pythonExts = import ./python.nix { enable = python; };
  nixExts = import ./nix.nix { enable = nix; };
  generalExts = [
    "arturock.gitstash"
    "bradzacher.vscode-coloured-status-bar-problems"
    "donjayamanne.githistory"
    "duniul.git-stage"
    "github.copilot"
    "github.copilot-chat"
    "github.vscode-github-actions"
    "github.vscode-pull-request-github"
    "gruntfuggly.todo-tree"
    "me-dutour-mathieu.vscode-github-actions"
    "mechatroner.rainbow-csv"
    "mhutchie.git-graph"
    "ms-edgedevtools.vscode-edge-devtools"
    "ms-vscode-remote.remote-ssh"
    "ms-vscode-remote.remote-ssh-edit"
    "ms-vscode-remote.remote-wsl"
    "ms-vscode.remote-explorer"
    "ms-vscode.vscode-github-issue-notebooks"
    "oderwat.indent-rainbow"
    "peterschmalfeldt.explorer-exclude"
    "pkief.material-icon-theme"
    # "redhat.ansible"
    "redhat.vscode-yaml"
    "streetsidesoftware.code-spell-checker"
    "tomblind.scm-buttons-vscode"
    "tomoki1207.pdf"
    "usernamehw.errorlens"
    "yzhang.markdown-all-in-one"
  ];
in
generalExts ++ rustExts ++ pythonExts ++ nixExts
