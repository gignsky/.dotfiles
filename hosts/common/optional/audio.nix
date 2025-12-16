# Audio configuration for NixOS systems with PipeWire
{ pkgs, ... }:
{
  # Enable sound with pipewire (sound.enable is deprecated)
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;

    # Low-latency audio configuration
    extraConfig.pipewire = {
      "10-high-quality-audio" = {
        "context.properties" = {
          "default.clock.rate" = 48000;
          "default.clock.quantum" = 256;
          "default.clock.min-quantum" = 128;
          "default.clock.max-quantum" = 512;
        };
      };
    };
  };

  # Enable media session for advanced bluetooth controls
  environment.systemPackages = with pkgs; [
    pipewire
    wireplumber
    # Real-time audio priority
    rtkit
  ];

  # Ensure user is in audio group
  users.users.gig.extraGroups = [ "audio" ];
}
