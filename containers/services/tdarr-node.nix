# Tdarr transcode node run-as-a-service container, ported verbatim from
# dot-spacedock. DISABLED by default (not imported by
# containers/services/default.nix).
#
# ⚠️  Before enabling: needs CIFS/samba mounts and /etc/samba/cifs-creds
# (provisioned via sops-nix), and the hardcoded server IP (192.168.51.3).
{ pkgs, lib, ... }:
let
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
in
{
  systemd.tmpfiles.rules = [
    "d /var/lib/tdarr/configs 0755 root root -"
    "d /var/lib/tdarr/logs 0755 root root -"
  ];
  virtualisation.oci-containers.containers.tdarr-node = {
    image = "ghcr.io/haveagitgat/tdarr_node:latest";
    autoStart = true;
    environment = {
      TZ = "America/New_York";
      PUID = "1000";
      PGID = "1000";
      # UMASK_SET = 002;
      nodeName = "spacedock";
      serverIP = "192.168.51.3";
      serverPort = "30029";
      inContainer = "true";
      #ffmpegVersion=7;
      nodeType = "mapped";
      priority = "-1";
      maxLogSizeMB = "10";
      pollInterval = "2000";
      # NVIDIA_DRIVER_CAPABILITIES="all";
      # NVIDIA_VISIBLE_DEVICES="all";
    };
    volumes = [
      "/opt/tdarr/media:/mnt"
      "/opt/tdarr/tdarr-cache:/temp"
      "/var/lib/tdarr/configs:/app/configs"
      "/var/lib/tdarr/logs:/app/logs"
    ];
  };
  fileSystems = lib.mkMerge [
    (newMount "media" "/opt/tdarr/media" "192.168.51.3" "1000" "1000")
    (newMount "tdarr-cache" "/opt/tdarr/tdarr-cache" "192.168.51.3" "1000" "1000")
  ];
  environment.systemPackages = [ pkgs.cifs-utils ];
}
