{
  programs.ssh = {
    enable = true;

    matchBlocks = {
      "github" = {
        host = "github.com";
        identitiesOnly = true;
        identityFile = "/home/gig/.ssh/id_rsa";
      };
    };
  };
}
