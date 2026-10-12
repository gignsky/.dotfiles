# The binary-cache scripts as standalone packages. Also exposed as flake
# packages so `nix run .#cache-push` works on hosts that haven't switched yet.
{
  lib,
  writers,
  git,
  nix,
  openssh,
  coreutils,
}:
let
  mkScript =
    name: deps:
    writers.writeNuBin name {
      makeWrapperArgs = [
        "--prefix"
        "PATH"
        ":"
        (lib.makeBinPath deps)
      ];
    } (builtins.readFile ./${name}.nu);
in
{
  cache-build = mkScript "cache-build" [
    nix
    git
    openssh
    coreutils
  ];
  cache-watch = mkScript "cache-watch" [
    nix
    git
    openssh
    coreutils
  ];
  cache-push = mkScript "cache-push" [
    nix
    openssh
  ];
}
