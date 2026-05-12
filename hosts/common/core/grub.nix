{
  # Grub installation
  boot.loader = {
    # Bootloader.
    systemd-boot.enable = false;
    grub = {
      enable = true;
      efiSupport = true;
      efiInstallAsRemovable = false;
      useOSProber = true; # Automatically detect Windows and other OSes
      configurationLimit = 20; # Limit boot menu entries to last 20 generations

      # default config
      default = "saved";
      extraConfig = ''
        GRUB_SAVEDEFAULT=true
      '';
    };
    efi.canTouchEfiVariables = true;
  };

}
