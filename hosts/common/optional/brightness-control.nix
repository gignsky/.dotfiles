{ pkgs, ... }:

{
  # Enable brightness control utilities and proper permissions
  environment.systemPackages = with pkgs; [
    brightnessctl # Modern brightness control utility
    light # Alternative brightness control (backup)
    acpilight # ACPI-based brightness control
  ];

  # Backlight udev rules and permissions
  services.udev.extraRules = ''
    # Framework laptop backlight permissions
    ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="amdgpu_bl*", RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness"
    ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="amdgpu_bl*", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"

    # Additional Framework-specific rules
    ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness"
    ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"
  '';

  # Ensure proper kernel modules are loaded for AMD GPU brightness control
  boot.kernelModules = [
    "amdgpu"
  ];

  # Framework-specific kernel parameters for better brightness control
  boot.kernelParams = [
    # Enable AMD GPU backlight control
    "amdgpu.backlight=1"
    # Ensure ACPI backlight interface is available
    "acpi_backlight=vendor"
  ];

  # Set up proper permissions for video group
  users.groups.video = { };

  # Systemd service to set proper permissions on boot (backup method)
  systemd.services.backlight-permissions = {
    description = "Set backlight permissions for video group";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udev-settle.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeScript "setup-backlight-permissions" ''
        #!${pkgs.bash}/bin/bash
        # Wait for backlight devices to appear
        sleep 2

        # Set permissions for all backlight devices
        for bl in /sys/class/backlight/*/brightness; do
          if [ -e "$bl" ]; then
            chgrp video "$bl" 2>/dev/null || true
            chmod g+w "$bl" 2>/dev/null || true
            echo "Set permissions for $bl"
          fi
        done
      '';
    };
  };
}
