{ inputs, ... }:
{
  nix.registry = {
    gigpgks.flake = inputs.gigpkgs;
  };
}
