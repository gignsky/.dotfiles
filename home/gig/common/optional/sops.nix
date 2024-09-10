{ inputs, ...}:

{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  sops = {
    # This is the gig/dev key and needs ot have been copied to this location on the host
    age.keyFile = "/home/gig/.config/sops/age/keys.txt";
  };

  defaultSopsFile = "/home/gig/.dotfiles/secrets.yaml";
  validateSopsFiles = false;

  secrets = {
    "private_keys/gig" = {
      path = "/home/gig/.ssh/id_demo";
    };
  };
}
