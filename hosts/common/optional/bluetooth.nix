# Bluetooth configuration for NixOS systems
{ pkgs, ... }:
{
  # Enable Bluetooth support
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true; # Power on the Bluetooth adapter when the system starts
    settings = {
      General = {
        # Enable A2DP (high-quality audio) and other audio profiles
        Enable = "Source,Sink,Media,Socket";
        Experimental = true; # Enable experimental features for better compatibility
      };
    };
  };

  # Enable Bluetooth management service
  services.blueman.enable = true;

  # Add Bluetooth utilities to system packages
  environment.systemPackages = with pkgs; [
    bluez # Bluetooth protocol stack
    bluez-tools # Additional Bluetooth utilities
  ];

  # Ensure the user is in the required groups for Bluetooth access
  users.users.gig.extraGroups = [ "bluetooth" ];

  # Enable PipeWire Bluetooth support (for audio)
  services.pipewire = {
    wireplumber.extraConfig = {
      "10-bluez" = {
        "monitor.bluez.properties" = {
          "bluez5.enable-sbc-xq" = true;
          "bluez5.enable-msbc" = true;
          "bluez5.enable-hw-volume" = true;
          "bluez5.headset-roles" = [
            "hsp_hs"
            "hsp_ag"
            "hfp_hf"
            "hfp_ag"
          ];
          # Enhanced codec support for OnePlus Buds 3
          "bluez5.enable-faststream" = true;
          "bluez5.enable-ldac" = true;
          "bluez5.enable-aptx" = true;
          "bluez5.enable-aac" = true;
          # Advanced control features
          "bluez5.autoconnect-profiles" = [
            "a2dp_sink"
            "a2dp_source"
            "hfp_hf"
            "hsp_hs"
            "avrcp"
          ];
          "bluez5.media-control" = true;
        };
      };
      # Enable media session for advanced controls
      "50-media-session-bluez-monitor" = {
        "properties" = {
          "bluez5.msbc-support" = true;
          "bluez5.sbc-xq-support" = true;
        };
      };
    };
  };
}
