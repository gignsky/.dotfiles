{ pkgs, config, ... }:

{
  sops.secrets.gig-password.neededForUsers = true;
  users.mutableUsers = false; # required for password to be set via sops during system activation

  imports = [
    # ./common/optional/sops.nix
    ../optional/zsh.nix
  ];

  # sops.secrets.gig-password.neededForUsers = true;
  # users.mutableUsers = false; # required for password to be set via sops during system activation

  users.users.gig = {
    # hashedPasswordFile = config.sops.secrets.gig-password.path;
    # If you do, you can skip setting a root password by passing '--no-root-passwd' to nixos-install.
    # Be sure to change it (using passwd) after rebooting!
    # initialPassword = "correcthorsebatterystaple";
    isNormalUser = true;
    # hashedPassword = config.sops.secrets.gig-password.path;
    openssh.authorizedKeys.keys = [
    ];
    # shell = pkgs.zsh; #default shell
    extraGroups = [
      "wheel"
      "gig"
    ];


  };

  users.users.tester = {
    isNormalUser = true;
    hashedPasswordFile = config.sops.secrets.gig-password.path;
    openssh.authorizedKeys.keys = [
    ];
    extraGroups = [
      "wheel"
    ];
  };

  # imports = [
  #   ../../optional/sshd-with-passwords.nix
  # ];

  services.openssh.enable = true;
}
