{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  options.bootloader = {
    kind = mkOption {
      type = types.enum [
        "grub"
        "systemd-boot"
        "refind"
        "none"
      ];
      default = "grub";
      description = "Select which bootloader to use: 'grub', 'systemd-boot', 'refind', or 'none' (for WSL). Default is 'grub'.";
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

    refind = {
      theme = mkOption {
        type = types.nullOr (
          types.enum [
            "gruvbox-dark"
            "darkmini"
            "minimal"
          ]
        );
        default = null;
        description = "rEFInd theme to use";
      };

      resolution = mkOption {
        type = types.str;
        default = "1920 1080";
        description = "Display resolution for rEFInd";
      };

      timeout = mkOption {
        type = types.int;
        default = 5;
        description = "Boot menu timeout in seconds";
      };

      showTools = mkOption {
        type = types.bool;
        default = true;
        description = "Show firmware and shell tools in menu";
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Extra configuration for refind.conf";
      };
    };
  };

  config = mkMerge [
    (mkIf (config.bootloader.kind == "grub") {
      boot.loader = {
        systemd-boot.enable = mkDefault false;
        grub = {
          enable = mkDefault true;
          inherit (config.bootloader.grub)
            useOSProber
            device
            efiSupport
            efiInstallAsRemovable
            ;
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

    (mkIf (config.bootloader.kind == "refind") {
      boot.loader = {
        systemd-boot.enable = mkDefault false;
        grub.enable = mkDefault false;
        efi.canTouchEfiVariables = mkDefault true;
      };

      # Install rEFInd using the refind package
      environment.systemPackages = [ pkgs.refind ];

      # rEFInd configuration
      boot.loader.efi.efiSysMountPoint = "/boot";

      # Custom refind.conf generation
      environment.etc."refind.conf" = {
        text = ''
          # rEFInd Configuration
          timeout ${toString config.bootloader.refind.timeout}
          resolution ${config.bootloader.refind.resolution}

          ${lib.optionalString config.bootloader.refind.showTools ''
            showtools shell, memtest, gdisk, mok_tool, about, hidden_tags, reboot, exit, firmware, fwupdate
          ''}

          # Scan for Linux kernels
          scan_driver_dirs EFI/refind/drivers_x64
          scanfor internal,external,optical,manual

          # OS detection
          dont_scan_volumes "Recovery HD"
          dont_scan_dirs ESP:/EFI/Boot,EFI/Dell,EFI/HP,EFI/Lenovo

          ${lib.optionalString (config.bootloader.refind.theme == "gruvbox-dark") ''
            # Gruvbox Dark Theme
            include themes/gruvbox-dark/theme.conf
          ''}

          ${lib.optionalString (config.bootloader.refind.theme == "darkmini") ''
            # Dark Mini Theme  
            include themes/darkmini/theme.conf
          ''}

          ${lib.optionalString (config.bootloader.refind.theme == "minimal") ''
            # Minimal Theme
            include themes/minimal/theme.conf
          ''}

          ${config.bootloader.refind.extraConfig}
        '';
        target = "refind.conf";
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
