{ inputs, ... }:
{
  environment.systemPackages = with inputs; [
    nix-sweep.nix-sweep
  ];
}
