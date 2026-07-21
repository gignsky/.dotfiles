# Mini Container Configuration
# Clean base image for building Docker layered images. Ported from dot-spacedock.
{
  inputs,
  lib,
  pkgs,
  system,
  ...
}:
{
  # Import base profiles for a good foundation
  imports = [
    "${inputs.nixpkgs}/nixos/modules/profiles/docker-container.nix"
    # Skip minimal.nix to avoid conflicts, we'll configure minimalism ourselves
  ];

  # Container-optimized boot configuration
  boot = {
    isContainer = true;
    loader.grub.enable = lib.mkForce false;
    kernelParams = [ "systemd.unified_cgroup_hierarchy=1" ];
  };

  # Modern Nix configuration for container builds
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
      substituters = [
        "https://cache.nixos.org/"
      ];
    };
    gc = {
      automatic = false; # Let users control GC in derived images
    };
  };

  # Clean networking setup
  networking = {
    hostName = lib.mkForce "mini";
    firewall.enable = lib.mkForce false; # Override docker-container.nix
    dhcpcd.enable = lib.mkDefault false;
    useHostResolvConf = lib.mkDefault true;
  };

  # Streamlined systemd - keep essential services only
  systemd = {
    enableEmergencyMode = false;
    services = {
      systemd-resolved.enable = lib.mkForce false;
      systemd-logind.enable = lib.mkForce false;
    };
  };

  # Clean user setup - root only for base image
  users = {
    mutableUsers = lib.mkDefault false;
    allowNoPasswordLogin = true; # This is a base container image
    users.root = {
      shell = pkgs.bash;
      # No password - derived images can set this
    };
  };

  # Base package set - good foundation without bloat
  environment = {
    systemPackages = with pkgs; [
      # Essential system tools
      bash
      coreutils
      findutils
      gnugrep
      gnused
      gawk
      util-linux
      procps

      # Container and build essentials
      gnutar
      gzip
      xz
      zstd
      curl
      wget
      cacert

      # Development basics (useful for derived images)
      git
      nano
      less
    ];

    # Keep minimal but functional
    defaultPackages = [ ];
    shells = [ pkgs.bash ];

    # Useful environment for containers
    variables = {
      EDITOR = "nano";
      PAGER = "less";
    };
  };

  # Keep documentation light but present for derived images
  documentation = {
    enable = lib.mkForce true; # Override minimal.nix
    man.enable = lib.mkDefault false; # Save space but allow override
    info.enable = lib.mkDefault false;
    nixos.enable = lib.mkDefault false;
  };

  # Essential services for container functionality
  services = {
    openssh.enable = lib.mkDefault false; # Can be enabled in derived images
    dbus.enable = lib.mkDefault true; # Often needed
    logrotate.enable = lib.mkDefault false;
  };

  # Useful programs for container work
  programs = {
    bash = {
      completion.enable = lib.mkDefault true;
      interactiveShellInit = ''
        # Container-friendly bash setup
        export PS1='\u@\h:\w\$ '
        alias ll='ls -la'
        alias la='ls -A'
        alias l='ls -CF'
      '';
    };
    less.enable = lib.mkDefault true;
    nano.enable = lib.mkDefault true;
  };

  # Basic security - can be enhanced in derived images
  security = {
    polkit.enable = lib.mkDefault false;
    sudo.enable = lib.mkDefault false; # Can be enabled in derived images
    pam.loginLimits = [
      {
        domain = "*";
        type = "soft";
        item = "nofile";
        value = "65536";
      }
      {
        domain = "*";
        type = "hard";
        item = "nofile";
        value = "65536";
      }
    ];
  };

  # Disable X11 - this is a server/CLI base
  services.xserver.enable = lib.mkForce false;
  hardware.graphics.enable = lib.mkForce false;

  # Container-appropriate filesystem
  fileSystems = lib.mkDefault { };

  # Provide a dummy vmTest for flake checks
  system.build.vmTest = pkgs.writeText "mini-vm-test" "# Container-only config, no VM test needed";

  system.stateVersion = "25.05";
}
