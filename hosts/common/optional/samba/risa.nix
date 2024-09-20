{ ... }:
{
  fileSystems."/home/gig/risa" = {
    device = "//192.168.51.3/risa";
    fsType = "cifs";
    options = let
      # this line prevents hanging on network split
      automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
      creds = "/etc/samba/cifs-creds";
      uid = "1000";
      gid = "100";
    in
    ["${automount_opts},credentials=${creds},uid=${uid},gid=${gid},vers=3.0"];
  };
}
