{ inputs, config, configLib, ...}:

let
  # secretsDirectory = builtins.toString inputs.nix-secrets;
  # secretsFile = "{secretsDirectory}/secrets.yaml";
  homeDirectory = config.home.homeDirectory;
in
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  sops = {
    # This is the gig/dev key and needs ot have been copied to this location on the host
    # age.keyFile = "/home/gig/.config/sops/age/keys.txt";
    # age = {
    #   # automatically import host SSH keys as age keys
    #   sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    #   #this will use an age key that is expected to already be in the filesystem
    #   keyFile = "/var/lib/sops-nix/key.txt";
    #   # generate a new key if the key specified above doesn't exist
    #   generateKey = true;
    # };

    age.keyFile = "${homeDirectory}/.config/sops/age/keys.txt";
    defaultSopsFile = (configLib.relativeToRoot "./secrets.yaml");
    validateSopsFiles = false;

    secrets = {
      "private_keys/dev" = {
        path = "${homeDirectory}/.ssh/id_rsa";
      };
    };

  };
}
