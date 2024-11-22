{ inputs, config, configLib, ...}:

let
  secretsDirectory = builtins.toString inputs.nix-secrets;
  secretsFile = "${secretsDirectory}/secrets.yaml";
in
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  sops = {
    # This is the gig/dev key and needs ot have been copied to this location on the host
    age.keyFile = "/home/gig/.config/sops/age/keys54321.txt";
    defaultSopsFile = ("${secretsFile}");
    validateSopsFiles = false;

    secrets = {
      "private_keys/dev" = {
        path = "/home/gig/.ssh/id_rsa";
      };
    };
  };
}
