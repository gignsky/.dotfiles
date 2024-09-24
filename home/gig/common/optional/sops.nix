{ inputs, configLib, ...}:

let
  secretsDirectory = builtins.toString inputs.nix-secrets;
  secretsFile = "${secretsDirectory}/secrets.yaml";
  homeDirectory = configLib.home.homeDirectory;
in
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  sops = {
    # This is the gig/dev key and needs ot have been copied to this location on the host
    age.keyFile = "/home/gig/.config/sops/age/keys.txt";
    defaultSopsFile = (configLib.relativeToRoot "./secrets.yaml");
    validateSopsFiles = false;

    secrets = {
      "private_keys/dev" = {
        path = "/home/gig/.ssh/id_rsa";
      };
    };

  };
}
