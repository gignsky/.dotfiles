{
  inputs,
  configLib,
  pkgs,
  ...
}:

{
  imports = [
    # inputs.sops-nix.nixosModules.sops

    ./appraisals.nix
    ./utility.nix
    ./risa.nix
  ];


  environment.systemPackages = [ pkgs.cifs-utils ];

  # This is for hosting a samba share
  # services.samba = {
  #   enable = true;
  #   # securityType = "auto"; # defaults to "user"
  #   # openFirewall = true; # defaults to false
  #   # extraConfig = '' # Some defaults from https://nixos.wiki/wiki/Samba
  #   #   workgroup = WORKGROUP
  #   #   server string = smbnix
  #   #   netbios name = smbnix
  #   #   security = user
  #   #   #use sendfile = yes
  #   #   #max protocol = smb2
  #   #   # note: localhost is the ipv6 localhost ::1
  #   #   hosts allow = 192.168.0. 127.0.0.1 localhost
  #   #   hosts deny = 0.0.0.0/0
  #   #   guest account = nobody
  #   #   map to guest = bad user
  #   # '';
  # };
}
