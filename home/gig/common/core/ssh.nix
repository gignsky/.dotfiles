{ outputs, lib, configLib, ... }:

let
  homeDirectory = configLib.home.homeDirectory;
in
{
  programs.ssh = {
    enable = true;

    matchBlocks = {
      "github" = {
        host = "github.com";
        identitiesOnly = true;
        identityFile = "${homeDirectory}/.ssh/id_rsa";
      };
    };
  };
}
