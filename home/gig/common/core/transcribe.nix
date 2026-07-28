# transcribe.nix — one command, any audio file in, transcript out.
#
# Import from home.nix:      imports = [ ./transcribe.nix ];
# or from configuration.nix: imports = [ ./transcribe.nix ];  (see the note at bottom)
#
# Usage once built:
#     transcribe "Some thoughts.mp3"
#     transcribe *.m4a
# Writes <name>.txt and <name>.srt beside each input file.

{ pkgs, lib, ... }:

let
  # The model, pinned and cached in the Nix store — fetched once, ever.
  #
  # FIRST BUILD: leave `hash` as lib.fakeHash. Nix will fail with
  #   "hash mismatch ... got: sha256-XXXX="
  # Paste that value in place of lib.fakeHash and rebuild. Done forever.
  whisperModel = pkgs.fetchurl {
    url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.en-tdrz.bin";
    hash = lib.fakeHash;
  };

  transcribe = pkgs.writeShellApplication {
    name = "transcribe";
    runtimeInputs = [
      pkgs.ffmpeg
      pkgs.whisper-cpp
    ];
    text = ''
      if [ $# -eq 0 ]; then
        echo "usage: transcribe <audio-file> [more-files...]" >&2
        exit 1
      fi

      tmp="$(mktemp -d)"
      trap 'rm -rf "$tmp"' EXIT

      for f in "$@"; do
        if [ ! -f "$f" ]; then
          echo "!! no such file: $f" >&2
          continue
        fi

        base="''${f%.*}"

        echo ":: converting $f -> 16kHz mono wav"
        ffmpeg -loglevel error -y -i "$f" \
          -ar 16000 -ac 1 -c:a pcm_s16le "$tmp/audio.wav"

        echo ":: transcribing (this is the slow part)"
        whisper-cpp \
          -m ${whisperModel} \
          -f "$tmp/audio.wav" \
          -t "$(nproc)" \
          --tinydiarize \
          -otxt -osrt \
          -of "$base"

        echo ":: wrote $base.txt and $base.srt"
      done
    '';
  };
in
{
  # home-manager:
  home.packages = [ transcribe ];

  # NixOS instead? swap the line above for:
  #   environment.systemPackages = [ transcribe ];
}
