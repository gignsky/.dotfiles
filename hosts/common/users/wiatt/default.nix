{ pkgs, config, lib, inputs, configLib, configVars, ... }:

let
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
  sopsHashedPasswordFile =
    lib.optionalString (lib.hasAttr "sops-nix" inputs)
      config.sops.secrets."${configVars.wiatt_username}-password".path;
  pubKeys = lib.filesystem.listFilesRecursive (./keys);

  # these are values we don't want to set if the environment is minimal. E.g. ISO or nixos-installer
  # isMinimal is true in the nixos-installer/flake.nix
  fullUserConfig = lib.optionalAttrs (!configVars.isMinimal) {
    users.users.${configVars.wiatt_username} = {
      hashedPasswordFile = sopsHashedPasswordFile;
      packages = [ pkgs.home-manager ];
    };

    # # Import this user's personal/home configurations
    # home-manager.users.${configVars.wiatt_username} = import (
    #   configLib.relativeToRoot "home/${configVars.wiatt_username}/${config.networking.hostName}.nix"
    # );
  };
in
{
  config =
    lib.recursiveUpdate fullUserConfig
      #this is the second argument to recursiveUpdate
      {
        users.groups.${configVars.wiatt_username} = {
          gid = 1702;
        };

        users.mutableUsers = false; # required for password to be set via sops during system activation
        users.users.${configVars.wiatt_username} = {
          home = "/home/${configVars.wiatt_username}";
          isNormalUser = true;
            password = if configVars.isMinimal then "nixos" else null; # Overridden if sops is working

          extraGroups =
            [ "wheel" "wiatt" ]
            ++ ifTheyExist [
              "audio"
              "video"
              "docker"
              "git"
              "networkmanager"
            ];

          # sets the user's id to 1701
          uid = lib.mkDefault 1702;

          # These get placed into /etc/ssh/authorized_keys.d/<name> on nixos
          openssh.authorizedKeys.keys = lib.lists.forEach pubKeys (key: builtins.readFile key);

          shell = if configVars.isMinimal then pkgs.bash else pkgs.zsh; # default shell
        };
      };
  # decrypt gig-password to /run/secrets-for-users/ so it can be used to create the user
  # sops.secrets.gig-password.neededForUsers = true;
  # sops.secrets.root-password.neededForUsers = true;
}
