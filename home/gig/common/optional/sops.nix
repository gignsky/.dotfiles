{ inputs, ...}:

{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  sops = {
    # This is the gig/dev key and needs ot have been copied to this location on the host
    age.keyFile = "/home/gig/.config/sops/age/keys.txt";

    defaultSopsFile = ../../../../secrets.yaml;
    validateSopsFiles = false;

    secrets = {
      "private_keys/dev" = {
        path = "/home/gig/.ssh/id_rsa";
      };
    };

  };
}
