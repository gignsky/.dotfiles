{ lib
, pkgs
, configLib
, configVars
, qemuGuest ? false
, ...
}:
let
  inherit (configVars.networking) sshPort;
in
{
  imports = [ (configLib.relativeToRoot "hosts/common/users/${configVars.username}") ];

  fileSystems."/boot".options = [ "umask=0077" ]; # Removes permissions and security warnings.
  boot = {
    loader.efi.canTouchEfiVariables = true;
    loader.systemd-boot = {
      enable = true;
      # we use Git for version control, so we don't need to keep too many generations.
      configurationLimit = lib.mkDefault 3;
      # pick the highest resolution for systemd-boot's console.
      consoleMode = lib.mkDefault "max";
    };
    initrd.systemd.enable = true;
  };

  # boot.loader.grub = {
  #   efiSupport = true;
  #   efiInstallAsRemovable = true;
  # };


  networking = {
    # configures the network interface(include wireless) via `nmcli` & `nmtui`
    networkmanager.enable = true;
  };

  services = {
    qemuGuest.enable = if qemuGuest then true else false;
    openssh = {
      enable = true;
      ports = [ sshPort ];
      settings.PermitRootLogin = "yes";
      # Fix LPE vulnerability with sudo use SSH_AUTH_SOCK: https://github.com/NixOS/nixpkgs/issues/31611
      # this mitigates the security issue caused by enabling u2fAuth in pam
      authorizedKeysFiles = lib.mkForce [ "/etc/ssh/authorized_keys.d/%u" ];
    };
  };

  # allow sudo over ssh with yubikey
  # this potentially causes a security issue that we mitigated above
  security.pam = {
    sshAgentAuth.enable = true;
    services.sudo = {
      u2fAuth = true;
      sshAgentAuth = true;
    };
  };

  environment.systemPackages = builtins.attrValues {
    inherit (pkgs)
      wget
      curl
      rsync
      git
      tree
      lolcat
      magic-wormhole
      just
      btop
      ;
  };

  programs.direnv = {
    enable = true;
    package = pkgs.direnv;
    silent = false;
    loadInNixShell = true;
    direnvrcExtra = "";
    nix-direnv = {
      enable = true;
      package = pkgs.nix-direnv;
    };
  };

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    warn-dirty = false;
  };
  system.stateVersion = "25.05";
}
