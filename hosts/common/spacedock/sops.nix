{ inputs, configLib, ... }:

let
  secretspath = builtins.toString inputs.nix-secrets;
in
{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];
  sops.secrets = {
    # dotunwrap-password = {
    #   neededForUsers = true;
    # };
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

}
