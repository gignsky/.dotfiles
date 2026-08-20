# Buzz Container Configuration
# Clean, minimal configuration based on spacedock.
# Ported from dot-spacedock. Built into an image by ./packages.nix /
# ./packages-podman.nix via nixos-generators (adhoc container mechanism).
{
  inputs,
  lib,
  config,
  configLib,
  pkgs,
  ...
}:
{
  # Import core spacedock modules (simplified)
  imports = [
    (configLib.relativeToRoot "hosts/common/core")
    (configLib.relativeToRoot "hosts/common/users/gig")
  ];

  # Container-optimized boot configuration
  boot = {
    loader.grub.enable = false;
    kernelPackages = pkgs.linuxPackages_6_12;
    isContainer = true;
    kernelParams = [ "systemd.unified_cgroup_hierarchy=1" ];
  };

  # Nix configuration (same as spacedock)
  nix =
    let
      flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
    in
    {
      settings = {
        experimental-features = "nix-command flakes";
        flake-registry = "";
        nix-path = config.nix.nixPath;
      };
      channel.enable = false;
      registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
    };

  # Container networking - override conflicting settings
  networking = {
    hostName = lib.mkForce "buzz";
    domain = "spacedock.local";
    useHostResolvConf = lib.mkDefault true;
    firewall = {
      enable = lib.mkForce true;
      allowedTCPPorts = [
        22
        80
        443
        2222
        8080
      ];
    };
  };

  # Container-optimized systemd
  systemd = {
    enableEmergencyMode = false;
    services = {
      systemd-resolved.enable = lib.mkForce false;
      systemd-timesyncd.enable = lib.mkForce false;
    };
  };

  # Essential packages
  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    vim
    htop
  ];

  # Container filesystem optimizations
  fileSystems."/tmp" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [
      "size=1G"
      "mode=1777"
    ];
  };

  system.stateVersion = "25.05";
}
