# Tdarr transcode node run-as-a-service container, ported verbatim from
# dot-spacedock. DISABLED by default (not imported by
# containers/services/default.nix).
#
# ⚠️  Before enabling: needs CIFS/samba mounts and /etc/samba/cifs-creds
# (provisioned via sops-nix), and the hardcoded server IP (192.168.51.3).
#
# GPU: spacedock carries a discrete AMD Polaris card (RX 470/480/570/580/590,
# PCI 1002:67df) bound to the in-tree `amdgpu` driver. This node hardware-
# transcodes via VA-API (radeonsi). The host must enable `hardware.graphics`
# with the VA-API userspace — see hosts/spacedock/default.nix. Polaris (VCE 3.4)
# encodes H.264 and 8-bit HEVC only; 10-bit HEVC and AV1 encode are not
# supported by the hardware, so Tdarr flows must target VAAPI H.264 / 8-bit HEVC.
{
  config,
  pkgs,
  lib,
  ...
}:
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
    };
    # AMD VA-API hardware transcode. Unlike NVIDIA, no special runtime is
    # needed (no --gpus, no nvidia-container-toolkit, no NVIDIA_* env) — the
    # stock tdarr_node image already ships the Mesa/VA-API userspace.
    #   1. Pass the whole /dev/dri tree (card + renderD nodes), not one node.
    #   2. Grant the host's numeric render+video GIDs so the container user can
    #      open /dev/dri/renderD128 instead of hitting EACCES. These come from
    #      NixOS's static allocations (config.ids.gids) — render=303, video=26 —
    #      NOT the Ubuntu 44/104 values, which are wrong on NixOS.
    extraOptions = [
      "--device=/dev/dri:/dev/dri"
      "--group-add=${toString config.ids.gids.render}"
      "--group-add=${toString config.ids.gids.video}"
    ];
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
