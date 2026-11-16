# Onboard audio (ALC1220 on the Starship/Matisse controller) for ganoslal.
#
# The analog headset sits on the rear Line Out jack and the ModMic on the rear
# Mic jack, while the speakers run off S/PDIF. ALSA's stock profiles only pair
# one output with one input, so picking the digital profile hides the headset
# and mic entirely. The analog and digital PCMs are separate hardware devices,
# so this profile set opens them together: both outputs plus the mic show up as
# their own sink/source and can be switched per-app (e.g. in Discord) or with
# pavucontrol without changing the card profile.
#
# Two follow-ups make that actually behave:
# - The HDA driver mirrors the analog PCM onto S/PDIF whenever the digital PCM
#   is idle ("IEC958 Default PCM Playback Switch"), so headset-only audio (e.g.
#   Discord) also came out of the speakers. That switch is turned off at boot.
# - USB sources outrank onboard ones, so the webcam mic became the default
#   input and apps that just record from the default (Claude Code voice) never
#   used the ModMic. The ModMic gets a higher session priority.
{ pkgs, ... }:
let
  profileSet = pkgs.writeText "ganoslal-onboard.conf" ''
    [General]
    auto-profiles = no

    [Mapping analog-stereo]
    device-strings = front:%f
    channel-map = left,right
    paths-output = analog-output analog-output-lineout analog-output-headphones
    paths-input = analog-input-front-mic analog-input-rear-mic analog-input-linein
    priority = 15

    [Mapping iec958-stereo]
    device-strings = iec958:%f
    channel-map = left,right
    paths-output = iec958-stereo-output
    direction = output
    priority = 5

    [Profile output:analog-stereo+output:iec958-stereo+input:analog-stereo]
    description = Headset + Digital Output + Mic
    output-mappings = analog-stereo iec958-stereo
    input-mappings = analog-stereo
    priority = 100

    [Profile output:analog-stereo+input:analog-stereo]
    description = Analog Stereo Duplex
    output-mappings = analog-stereo
    input-mappings = analog-stereo
    priority = 50

    [Profile output:iec958-stereo+input:analog-stereo]
    description = Digital Stereo (IEC958) Output + Analog Stereo Input
    output-mappings = iec958-stereo
    input-mappings = analog-stereo
    priority = 40
  '';
in
{
  services.pipewire.wireplumber.extraConfig."51-ganoslal-onboard-audio" = {
    "monitor.alsa.rules" = [
      {
        matches = [ { "device.name" = "alsa_card.pci-0000_2f_00.4"; } ];
        actions.update-props = {
          "device.profile-set" = "${profileSet}";
          "device.profile" = "output:analog-stereo+output:iec958-stereo+input:analog-stereo";
        };
      }
      {
        matches = [ { "node.name" = "~alsa_output.pci-0000_2f_00.4.analog-stereo*"; } ];
        actions.update-props."node.description" = "Headset (rear line out)";
      }
      {
        matches = [ { "node.name" = "~alsa_input.pci-0000_2f_00.4.analog-stereo*"; } ];
        actions.update-props = {
          "node.description" = "ModMic (rear mic)";
          "priority.session" = 2500;
        };
      }
    ];
  };

  systemd.services.ganoslal-unshare-spdif = {
    description = "Stop mirroring analog playback onto S/PDIF";
    wantedBy = [ "sound.target" ];
    after = [ "sound.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.alsa-utils}/bin/amixer -c Generic cset name='IEC958 Default PCM Playback Switch' off";
    };
  };
}
