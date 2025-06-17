{ config, lib, ... }:
with lib;
{
  options.bootloader.kind = mkOption {
    type = types.enum [ "refind" "systemd-boot" "grub" "none" ];
    default = "grub";
    description = "Select which bootloader to use: 'refind', 'systemd-boot', 'grub', or 'none' (for WSL). Default is 'grub'.";
  };

  config = mkIf (config.bootloader.kind == "refind")
    {
      boot.loader.systemd-boot.enable = false;
      boot.loader.refind.enable = true;
      boot.loader.refind.extraConfig = "scanfor internal,external,optical,manual";
      boot.loader.grub.enable = false;
    } // mkIf (config.bootloader.kind == "systemd-boot") {
    boot.loader.systemd-boot.enable = true;
    boot.loader.refind.enable = false;
    boot.loader.grub.enable = false;
  } // mkIf (config.bootloader.kind == "grub") {
    boot.loader.systemd-boot.enable = false;
    boot.loader.refind.enable = false;
    boot.loader.grub.enable = true;
    boot.loader.grub.version = 2;
    boot.loader.grub.useOSProber = true;
    boot.loader.grub.device = "nodev";
    boot.loader.grub.efiSupport = true;
    boot.loader.grub.efiInstallAsRemovable = true;
  } // mkIf (config.bootloader.kind == "none") {
    boot.loader.systemd-boot.enable = false;
    boot.loader.refind.enable = false;
    boot.loader.grub.enable = false;
  };
}
