{ pkgs, config, lib, inputs, configLib, configVars, ... }:

let
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
  sopsHashedPasswordFile =
    lib.optionalString (lib.hasAttr "sops-nix" inputs)
      config.sops.secrets."${configVars.username}-password".path;
  sopsRootHashedPasswordFile =
    lib.optionalString (lib.hasAttr "sops-nix" inputs)
      config.sops.secrets."root-password".path;
  pubKeys = lib.filesystem.listFilesRecursive (./keys);

  # these are values we don't want to set if the environment is minimal. E.g. ISO or nixos-installer
  # isMinimal is true in the nixos-installer/flake.nix
  fullUserConfig = lib.optionalAttrs (!configVars.isMinimal) {
    users.users.${configVars.username} = {
      hashedPasswordFile = sopsHashedPasswordFile;
      packages = [ pkgs.home-manager ];
    };

    users.users.root = {
      hashedPasswordFile = sopsRootHashedPasswordFile;
    };

    # # Import this user's personal/home configurations
    # home-manager.users.${configVars.username} = import (
    #   configLib.relativeToRoot "home/${configVars.username}/${config.networking.hostName}.nix"
    # );
  };
in
{
  config =
    lib.recursiveUpdate fullUserConfig
      #this is the second argument to recursiveUpdate
      {
        users = {
          groups.${configVars.username} = {
            gid = 1701;
          };
          mutableUsers = false; # required for password to be set via sops during system activation
          users.${configVars.username} = {
            home = "/home/${configVars.username}";
            isNormalUser = true;
            password = if configVars.isMinimal then "nixos" else null; # Overridden if sops is working
            extraGroups =
              [ "wheel" "gig" ]
              ++ ifTheyExist [
                "audio"
                "video"
                "docker"
                "git"
                "networkmanager"
              ];

            # sets the user's id to 1701
            uid = lib.mkDefault 1701;

            # These get placed into /etc/ssh/authorized_keys.d/<name> on nixos
            openssh.authorizedKeys.keys = lib.lists.forEach pubKeys (key: builtins.readFile key);

            shell = if configVars.isMinimal then pkgs.bash else pkgs.zsh; # default shell
          };

          # Proper root use required for borg and some other specific operations
          users.root = {
            password = if configVars.isMinimal then "nixos" else null; # Overridden if sops is working
            # root's ssh keys are mainly used for remote deployment.
            openssh.authorizedKeys.keys = config.users.users.${configVars.username}.openssh.authorizedKeys.keys;
          };
        };
      };
  # decrypt gig-password to /run/secrets-for-users/ so it can be used to create the user
  # sops.secrets.gig-password.neededForUsers = true;
  # sops.secrets.root-password.neededForUsers = true;
}
