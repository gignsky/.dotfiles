{ config, configLib, ... }:

{
  # decrypt gig-password to /run/secrets-for-users/ so it can be used to create the user
  sops.secrets.gig-password.neededForUsers = true;
  users.mutableUsers = false; # required for password to be set via sops during system activation

  imports = [
    # ./common/optional/sops.nix
    (configLib.relativeToRoot "hosts/common/optional/zsh.nix")
  ];

  # sops.secrets.gig-password.neededForUsers = true;
  # users.mutableUsers = false; # required for password to be set via sops during system activation

  users.users.root.hashedPasswordFile = config.sops.secrets.root-password.path;

  users.users.gig = {
    # If you do, you can skip setting a root password by passing '--no-root-passwd' to nixos-install.
    # Be sure to change it (using passwd) after rebooting!
    # initialPassword = "correcthorsebatterystaple";
    isNormalUser = true;
    hashedPasswordFile = config.sops.secrets.gig-password.path;
    openssh.authorizedKeys.keys = [
      (builtins.readFile ./keys/id_rsa.pub)
    ];
    # shell = pkgs.zsh; #default shell
    extraGroups = [
      "wheel"
      "gig"
    ];
  };

  # imports = [
  #   ../../optional/sshd-with-passwords.nix
  # ];


  services.openssh.enable = true;
}
