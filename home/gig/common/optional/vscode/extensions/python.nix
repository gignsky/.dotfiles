{ enable ? true }:

# Python-related VS Code extensions
if enable then [
  "cstrap.python-snippets"
  "ms-python.debugpy"
  "ms-python.python"
  "ms-python.vscode-pylance"
] else [ ]
