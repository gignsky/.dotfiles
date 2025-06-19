{ config, lib, ... }:
with lib;
{
  options.bootloader = {
    kind = mkOption {
      type = types.enum [ "grub" "systemd-boot" "none" ];
      default = "grub";
      description = "Select which bootloader to use: 'grub', 'systemd-boot', or 'none' (for WSL). Default is 'grub'. Note: rEFInd is not available as a built-in option in NixOS.";
    };

    grub = {
      useOSProber = mkOption {
        type = types.bool;
        default = true;
        description = "Enable OS detection with os-prober";
      };

      efiSupport = mkOption {
        type = types.bool;
        default = true;
        description = "Enable EFI support";
      };

      efiInstallAsRemovable = mkOption {
        type = types.bool;
        default = true;
        description = "Install as removable EFI";
      };

      device = mkOption {
        type = types.str;
        default = "nodev";
        description = "GRUB device (use 'nodev' for UEFI)";
      };
    };

    systemd-boot = {
      configurationLimit = mkOption {
        type = types.int;
        default = 10;
        description = "Maximum number of generations in the boot menu";
      };

      consoleMode = mkOption {
        type = types.str;
        default = "max";
        description = "Console mode for systemd-boot";
      };
    };
  };

  config = mkMerge [
    (mkIf (config.bootloader.kind == "grub") {
      boot.loader = {
        systemd-boot.enable = mkDefault false;
        grub = {
          enable = mkDefault true;
          inherit (config.bootloader.grub) useOSProber device efiSupport efiInstallAsRemovable;
        };
      };
    })

    (mkIf (config.bootloader.kind == "systemd-boot") {
      boot.loader = {
        systemd-boot = {
          enable = mkDefault true;
          inherit (config.bootloader.systemd-boot) configurationLimit consoleMode;
        };
        grub.enable = mkDefault false;
        efi.canTouchEfiVariables = mkDefault true;
      };
    })

    (mkIf (config.bootloader.kind == "none") {
      boot.loader = {
        systemd-boot.enable = mkDefault false;
        grub.enable = mkDefault false;
      };
    })
  ];
}
