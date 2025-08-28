{
  programs.ssh = {
    enable = true;

    matchBlocks = {
      "github" = {
        hostname = "github.com";
        identitiesOnly = true;
        identityFile = "/home/gig/.ssh/id_rsa";
      };
      "spacedock" = {
        hostname = "192.168.51.2";
        identitiesOnly = true;
        identityFile = "/home/gig/.ssh/gment";
      };
      # "giglab" = {
      #   hostname = "giglab.dev";
      #   identitiesOnly = true;
      #   identityFile = "/home/gig/.ssh/gment";
      # };
    };
  };
}
