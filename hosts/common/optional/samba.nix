{
  inputs,
  configLib,
  lib,
  pkgs,
  ...
}:

let
  newMount =
    shareName: mountPoint: fqdm: uid: gid:
    {
      "${mountPoint}" = {
        device = "//${fqdm}/${shareName}";
        fsType = "cifs";
        options = let
          # this line prevents hanging on network split
          automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
          creds = "/etc/samba/cifs-creds";
        in
        ["${automount_opts},credentials=${creds},uid=${uid},gid=${gid},vers=3.0"];
      };
    };
in
{
  # imports = (configLib.scanPaths ./.);

  # This is for mounting a samba share
  # name = newMount "shareName" "mountPoint" "fqdm" "uid" "gid";
  fileSystems = lib.mkMerge [
    (newMount "risa" "/home/gig/risa" "192.168.51.3" "1000" "100")
    (newMount "utility" "/home/gig/utility" "192.168.51.3" "1000" "100")
    (newMount "virtualization-boot-files" "/home/gig/virtualization-boot-files" "192.168.51.3" "1000" "100")
    (newMount "appraisals" "/home/gig/appraisals" "192.168.51.21" "1000" "100")
    (newMount "vulcan" "/home/gig/vulcan" "192.168.51.3" "1000" "100")
    (newMount "proxmox_backups_2" "/home/gig/proxmox_backups_2" "192.168.51.21" "1000" "100")
    (newMount "proxmox_backups" "/home/gig/proxmox_backups" "192.168.51.3" "1000" "100")
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
