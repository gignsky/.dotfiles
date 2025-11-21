{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.bootloader;
  inherit (config.boot.loader) efi;

  # rEFInd installation script following NixOS bootloader patterns
  refindInstallScript = pkgs.writeScript "install-refind.sh" ''
    #!${pkgs.runtimeShell}
    set -e

    # Variables passed by NixOS bootloader framework
    configurationName="$1"

    echo "Installing rEFInd bootloader..."

    # Check that EFI System Partition is mounted
    if ! ${pkgs.util-linuxMinimal}/bin/findmnt ${efi.efiSysMountPoint} > /dev/null; then
      echo "Error: EFI System Partition not mounted at ${efi.efiSysMountPoint}" >&2
      exit 1
    fi

    # Install rEFInd to the EFI System Partition
    echo "Running refind-install..."
    ${pkgs.refind}/bin/refind-install --usedefault ${efi.efiSysMountPoint}

    # Copy our generated configuration
    echo "Installing rEFInd configuration..."
    ${pkgs.coreutils}/bin/cp /etc/refind.conf ${efi.efiSysMountPoint}/EFI/refind/refind.conf

    # Note: External themes need to be installed separately
    # The refind package doesn't include custom themes by default
    ${lib.optionalString (cfg.refind.theme != null) ''
      echo "Note: Theme ${cfg.refind.theme} configured - ensure theme files are available in /boot/EFI/refind/themes/"
    ''}

    # Copy additional rEFInd resources (icons, tools, etc.)
    echo "Installing rEFInd resources..."
    ${pkgs.coreutils}/bin/cp -r ${pkgs.refind}/share/refind/icons ${efi.efiSysMountPoint}/EFI/refind/ || true
    ${pkgs.coreutils}/bin/cp -r ${pkgs.refind}/share/refind/drivers_* ${efi.efiSysMountPoint}/EFI/refind/ || true
    ${pkgs.coreutils}/bin/cp -r ${pkgs.refind}/share/refind/tools_* ${efi.efiSysMountPoint}/EFI/refind/ || true

    echo "rEFInd installation completed successfully."
  '';

in
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
          inherit (config.bootloader.systemd-boot)
            configurationLimit
            consoleMode
            ;
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
        efi.efiSysMountPoint = mkDefault "/boot";
      };

      # Core NixOS bootloader integration
      system = {
        build.installBootLoader = refindInstallScript;
        boot.loader.id = "refind";
        requiredKernelConfig = with config.lib.kernelConfig; [ (isYes "EFI_STUB") ];
      };

      # Install rEFInd package
      environment.systemPackages = [ pkgs.refind ];

      # Generate rEFInd configuration
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

          # NixOS kernel detection
          also_scan_dirs boot,@/boot

          # Theme configuration (only if theme files are available)
          ${lib.optionalString (config.bootloader.refind.theme != null) ''
            # Theme: ${config.bootloader.refind.theme}
            # Note: Theme files must be manually placed in /boot/EFI/refind/themes/
            # Uncomment the following line once theme files are installed:
            # include themes/${config.bootloader.refind.theme}/theme.conf
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
