{ lib, ... }:
{
  networking = import ./networking.nix { inherit lib; };

  username = "gig";
  #domain = inputs.nix-secrets.domain;
  #userFullName = inputs.nix-secrets.full-name;
  handle = "gignsky";
  #userEmail = inputs.nix-secrets.user-email;
  # gitHubEmail = "7410928+emergentmind@users.noreply.github.com";
  # gitLabEmail = "2889621-emergentmind@users.noreply.gitlab.com";
  #workEmail = inputs.nix-secrets.work-email;
  persistFolder = "/persist";
  isMinimal = false; # Used to indicate nixos-installer build

  # wiatt_username = "wiatt";
}
