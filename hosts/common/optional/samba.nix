{
  lib,
  pkgs,
  configVars,
  ...
}:

let
  # Core mount function that accepts all parameters
  newMount = shareName: mountPoint: fqdm: uid: gid: {
    "${mountPoint}" = {
      device = "//${fqdm}/${shareName}";
      fsType = "cifs";
      options =
        let
          # this line prevents hanging on network split
          automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
          creds = "/etc/samba/cifs-creds";
        in
        [ "${automount_opts},credentials=${creds},uid=${uid},gid=${gid},vers=3.0" ];
    };
  };

  # Convenience function using default configVars uid/gid
  defaultMount =
    shareName: mountPoint: fqdm:
    newMount shareName mountPoint fqdm (toString configVars.uid) (toString configVars.guid);
in
{
  # This is for mounting samba shares
  # Examples:
  # - defaultMount "shareName" "mountPoint" "fqdm"  # Uses configVars.uid/guid
  # - newMount "shareName" "mountPoint" "fqdm" "uid" "gid"  # Full control

  fileSystems = lib.mkMerge [
    (defaultMount "risa" "/home/gig/mnt/risa" "192.168.51.3")
    (defaultMount "utility" "/home/gig/mnt/utility" "192.168.51.3")
    (defaultMount "virtualization-boot-files" "/home/gig/mnt/virtualization-boot-files" "192.168.51.3")
    (defaultMount "vulcan" "/home/gig/mnt/vulcan" "192.168.51.3")
    (defaultMount "media" "/home/gig/mnt/media" "192.168.51.3")
    (defaultMount "appraisals" "/home/gig/mnt/appraisals" "192.168.51.21")
    (defaultMount "proxmox-backup-share" "/home/gig/mnt/proxmox_backups" "192.168.51.3")
    (defaultMount "important-app-data" "/home/gig/mnt/important-app-data" "192.168.51.3")
    (defaultMount "nzbget" "/home/gig/mnt/nzbget" "192.168.51.3")
    (defaultMount "tdarr-cache" "/home/gig/mnt/tdarr-cache" "192.168.51.3")
    (defaultMount "caches" "/home/gig/mnt/caches" "192.168.51.3")
    (defaultMount "plex-database" "/home/gig/mnt/plex-database" "192.168.51.3")
    # (defaultMount "media" "/home/gig/mnt/dad/media" "192.168.4.15")
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
