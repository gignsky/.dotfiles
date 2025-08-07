# NOTE: ... is needed because disko passes diskoFile
{
  disk ? "/dev/sda",
  ...
}:
{
  disko.devices = {
    disk.disk1 = {
      device = disk;
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            name = "boot";
            size = "1M";
            type = "EF02";
          };
          esp = {
            name = "ESP";
            size = "500M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              # Use extraArgs to set the filesystem label for vfat
              extraArgs = [
                "-n"
                "BOOT"
              ]; # -n is for setting the label in mkfs.vfat
            };
          };
          root = {
            name = "root";
            size = "100%";
            content = {
              type = "zfs";
              pool = "zroot";
            };
          };
        };
      };
    };
    zpool = {
      zroot = {
        type = "zpool";
        rootFsOptions = {
          mountpoint = "none";
        };
        datasets = {
          root = {
            type = "zfs_fs";
            mountpoint = "/";
            options = {
              canmount = "noauto";
              mountpoint = "/";
            };
          };
          nix = {
            type = "zfs_fs";
            mountpoint = "/nix/store";
            options = {
              canmount = "on";
              mountpoint = "/nix/store";
            };
          };
        };
      };
    };
  };
}
