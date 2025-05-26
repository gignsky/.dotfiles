{ pkgs
, lib
, configLib
, configVars
, ...
}:
let
  sshPort = configVars.networking.sshPort;
in
{
  imports = [ (configLib.relativeToRoot "hosts/common/users/${configVars.username}") ];

  # The default compression-level is (6) and takes too long on some machines (>30m). 3 takes <2m
  # isoImage.squashfsCompression = "zstd -Xcompression-level 3";

  nixpkgs = {
    hostPlatform = lib.mkDefault "x86_64-linux";
    config.allowUnfree = true;
  };

  # FIXME: Reference generic nix file
  nix = {
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    extraOptions = "experimental-features = nix-command flakes";
  };

  services = {
    qemuGuest.enable = true;
    openssh = {
      ports = [ sshPort ];
      settings.PermitRootLogin = lib.mkForce "yes";
    };
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_6_1; # pinned to a specific kernel version to avoid zfs-kernel module being marked as broken
    supportedFilesystems = lib.mkForce [
      "btrfs"
      "vfat"
      "zfs"
    ];
  };

  networking = {
    hostName = "iso";
  };

  environment.systemPackages = with pkgs; [
    magic-wormhole
    btop
    bat
  ];

  environment.shellAliases = {
    cat = "bat";
    ll = "ls -lh";
    lla = "ls -lha";
  };

  systemd = {
    services.sshd.wantedBy = lib.mkForce [ "multi-user.target" ];
    # gnome power settings to not turn off screen
    targets = {
      sleep.enable = false;
      suspend.enable = false;
      hibernate.enable = false;
      hybrid-sleep.enable = false;
    };
  };
}
