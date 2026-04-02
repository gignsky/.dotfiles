{ inputs, configLib, ... }:

{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  users.mutableUsers = false; # required for passwords to be set via sops during system activation
  sops = {
    defaultSopsFile = configLib.relativeToRoot "sops/secrets.yaml";
    validateSopsFiles = true;

    age = {
      # automatically import host SSH keys as age keys
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      #this will use an age key that is expected to already be in the filesystem
      keyFile = "/var/lib/sops-nix/key.txt";
      # generate a new key if the key specified above doesn't exist
      generateKey = true;
    };

    secrets = {
      gig-password = {
        neededForUsers = true;
      };
      dotunwrap-password = {
        neededForUsers = true;
      };
      root-password = {
        neededForUsers = true;
      };
      cifs-creds = {
        path = "/etc/samba/cifs-creds";
      };
      "gitlab/root-password" = {
        path = "/etc/gitlab/root-password.txt";
        owner = "gitlab";
        group = "gitlab";
        mode = "0400";
      };
      "gitlab/secrets-file" = {
        path = "/etc/gitlab/secretsfile.txt";
        owner = "gitlab";
        group = "gitlab";
        mode = "0400";
      };
      "gitlab/db-file" = {
        path = "/etc/gitlab/dbfile.txt";
        owner = "gitlab";
        group = "gitlab";
        mode = "0400";
      };
      "gitlab/otp-file" = {
        path = "/etc/gitlab/otpfile.txt";
        owner = "gitlab";
        group = "gitlab";
        mode = "0400";
      };
      "gitlab/jws-file" = {
        path = "/etc/gitlab/jwsfile.pem";
        owner = "gitlab";
        group = "gitlab";
        mode = "0400";
      };
      "gitlab/active-record/primary-key-file" = {
        path = "/etc/gitlab/active_record_primary_key.txt";
        owner = "gitlab";
        group = "gitlab";
        mode = "0400";
      };
      "gitlab/active-record/deterministic-key-file" = {
        path = "/etc/gitlab/active_record_deterministic_key.txt";
        owner = "gitlab";
        group = "gitlab";
        mode = "0400";
      };
      "gitlab/active-record/salt-file" = {
        path = "/etc/gitlab/active_record_salt.txt";
        owner = "gitlab";
        group = "gitlab";
        mode = "0400";
      };
    };
  };
}
