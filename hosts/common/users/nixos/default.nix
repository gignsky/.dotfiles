{
  pkgs,
  config,
  lib,
  # inputs,
  configVars,
  # outputs,
  ...
}:
let
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
  # sopsHashedPasswordFile =
  #   lib.optionalString (lib.hasAttr "sops-nix" inputs)
  #     config.sops.secrets."${configVars.username}-password".path;
  # # sopsRootHashedPasswordFile =
  # #   lib.optionalString (lib.hasAttr "sops-nix" inputs)
  # #     config.sops.secrets."root-password".path;
  # pubKeys = lib.filesystem.listFilesRecursive (./keys);

  # these are values we don't want to set if the environment is minimal. E.g. ISO or nixos-installer
  # isMinimal is true in the nixos-installer/flake.nix
  fullUserConfig = lib.optionalAttrs (!configVars.isMinimal) {
    users.users.${configVars.username} = {
      packages = [ pkgs.home-manager ];
    };

    # Removed users.users.root here to avoid duplicate password options
  };
in
# overlays
# nixpkgs.overlays = [
#   outputs.overlays.unstable-packages
#   # outputs.overlays.wrap-packages # example for overlays
# ];
{
  config =
    lib.recursiveUpdate fullUserConfig
      #this is the second argument to recursiveUpdate
      {
        users = {
          groups.nixos = {
            gid = 1000;
          };
          mutableUsers = false; # required for password to be set via sops during system activation
          users.nixos = {
            home = "/home/nixos";
            isNormalUser = true;
            password = "nixos"; # Overridden if sops is working
            extraGroups =
              [
                "wheel"
              ]
              ++ ifTheyExist [
                "audio"
                "video"
                "docker"
                "git"
                "networkmanager"
              ];

            # sets the user's id to 1701
            uid = lib.mkDefault 1000;

            # These get placed into /etc/ssh/authorized_keys.d/<name> on nixos
            # openssh.authorizedKeys.keys = lib.lists.forEach pubKeys (key: builtins.readFile key);

            # shell = if configVars.isMinimal then pkgs.bash else pkgs.unstable.nushell; # default shell
            # shell = pkgs.unstable.nushell; # default shell
          };

          # # Proper root use required for borg and some other specific operations
          # users.root = {
          #   password = if configVars.isMinimal then "nixos" else null; # Overridden if sops is working
          #   # root's ssh keys are mainly used for remote deployment.
          #   openssh.authorizedKeys.keys = config.users.users.${configVars.username}.openssh.authorizedKeys.keys;
          # };
        };
      };
  # decrypt gig-password to /run/secrets-for-users/ so it can be used to create the user
  # sops.secrets.gig-password.neededForUsers = true;
  # sops.secrets.root-password.neededForUsers = true;
}
