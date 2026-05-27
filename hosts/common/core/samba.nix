{
  lib,
  pkgs,
  configVars,
  ...
}:

let
  # Helper to normalize mount paths
  # If path starts with '/', use as absolute path, otherwise prefix with /home/username/
  normalizeMountPoint =
    mountPoint:
    if lib.hasPrefix "/" mountPoint then
      mountPoint # Absolute path, use as-is
    else
      "/home/${configVars.username}/${mountPoint}"; # Relative to user home

  # Core mount function that accepts all parameters
  newMount =
    shareName: mountPoint: fqdm: uid: gid:
    let
      fullMountPoint = normalizeMountPoint mountPoint;
    in
    {
      "${fullMountPoint}" = {
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
    newMount shareName mountPoint fqdm (toString configVars.uid) (toString configVars.gid);
in
{
  # This is for mounting samba shares
  # Examples:
  # - defaultMount "shareName" "mnt/mountPoint" "fqdm"           # → /home/gig/mnt/mountPoint (relative)
  # - defaultMount "shareName" "/absolute/path" "fqdm"          # → /absolute/path (absolute)
  # - newMount "shareName" "mnt/custom" "fqdm" "uid" "gid"      # → /home/gig/mnt/custom (relative, custom uid/gid)
  # - newMount "shareName" "/mnt/system/share" "fqdm" "uid" "gid" # → /mnt/system/share (absolute, custom uid/gid)

  fileSystems = lib.mkMerge [
    (defaultMount "risa" "mnt/risa" "192.168.51.3")
    (defaultMount "utility" "mnt/utility" "192.168.51.3")
    (defaultMount "virtualization-boot-files" "mnt/virtualization-boot-files" "192.168.51.3")
    (defaultMount "vulcan" "mnt/vulcan" "192.168.51.3")
    (defaultMount "media" "mnt/media" "192.168.51.3")
    (defaultMount "appraisals" "mnt/appraisals" "192.168.51.21")
    (defaultMount "proxmox-backup-share" "mnt/proxmox_backups" "192.168.51.3")
    (defaultMount "important-app-data" "mnt/important-app-data" "192.168.51.3")
    (defaultMount "nzbget" "mnt/nzbget" "192.168.51.3")
    (defaultMount "tdarr-cache" "mnt/tdarr-cache" "192.168.51.3")
    (defaultMount "caches" "mnt/caches" "192.168.51.3")
    (defaultMount "plex-database" "mnt/plex-database" "192.168.51.3")
    # Example absolute path: (defaultMount "media" "/mnt/dad/media" "192.168.4.15")
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
