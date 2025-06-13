{ enable ? true }:

# Rust-related VS Code extensions
if enable then [
  "belfz.search-crates-io"
  "dustypomerleau.rust-syntax"
  "kevinkassimo.cargo-toml-snippets"
  "taiyuuki.vscode-cargo-scripts"
  "tamasfe.even-better-toml"
  "washan.cargo-appraiser"
] else [ ]
