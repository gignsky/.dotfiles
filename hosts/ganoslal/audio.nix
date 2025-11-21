{ pkgs, ... }:
{
  # SPDIF Optical Audio Configuration for XFCE

  # Ensure audio group exists and user has permissions
  users.users.gig.extraGroups = [ "audio" ];

  # Additional ALSA configuration for SPDIF
  environment.etc."asound.conf".text = ''
    defaults.pcm.card 0
    defaults.pcm.device 0
    defaults.ctl.card 0

    # SPDIF optical output configuration
    pcm.spdif {
      type hw
      card 0
      device 1
    }

    ctl.spdif {
      type hw
      card 0
    }

    # Make SPDIF available as a named device
    pcm.optical {
      type hw
      card 0
      device 1
    }
  '';

  # Additional PulseAudio/PipeWire configuration for XFCE
  environment.systemPackages = with pkgs; [
    pavucontrol # PulseAudio Volume Control GUI
    alsa-utils # ALSA utilities including amixer
    pulseaudio # PulseAudio tools even when using PipeWire
  ];

  # Ensure audio services start properly
  systemd.user.services.pipewire-pulse.wantedBy = [ "default.target" ];
}
