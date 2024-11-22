{ inputs, configLib, ... }:

let
    secretspath = builtins.toString inputs.nix-secrets;
in
{
    imports = [
        inputs.sops-nix.nixosModules.sops
    ];

    sops = {
        defaultSopsFile = ("${secretspath}/secrets.yaml");
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
            root-password = {
                neededForUsers = true;
            };
            cifs-creds = {
                path = "/etc/samba/cifs-creds";
            };
        };
    };
}
