# transcribe.nix — one command, any audio file in, a speaker-labelled
# transcript out. WhisperX: faster-whisper for the words, wav2vec2 forced
# alignment for the timing, pyannote for who-spoke-when.
#
# Import from home.nix:      imports = [ ./transcribe.nix ];
# or from configuration.nix: imports = [ ./transcribe.nix ];  (see bottom)
#
# One-time setup:
#   mkdir -p ~/.config/whisperx && chmod 700 ~/.config/whisperx
#   printf '%s' 'hf_xxxxxxxx' > ~/.config/whisperx/token
#   chmod 600 ~/.config/whisperx/token
#
# Usage:
#   transcribe interview.mp3          # let pyannote guess the speaker count
#   transcribe -n 2 interview.mp3     # tell it there are exactly two — better
#   transcribe -n 3 *.m4a             # several files in one go
#
# Writes, beside each input file:
#   <name>.transcript.md   ← the readable one, turns grouped by speaker
#   <name>.srt             ← subtitles, word-accurate
#   <name>.json            ← the full structured output, word-level

{ pkgs, ... }:

let
  # ── Knobs ────────────────────────────────────────────────────────────
  model = "large-v3"; # large-v3-turbo is ~4x faster, slightly worse
  language = "en"; # "" to auto-detect, at the cost of a probe pass

  # nixpkgs' ctranslate2 is built WITHOUT CUDA by default, so "cuda" here
  # will fail until you either set nixpkgs.config.cudaSupport = true (add
  # the cuda-maintainers cachix first, or you will rebuild the world) or
  # override ctranslate2 alone. "cpu" always works; it is merely patient.
  device = "cpu";

  computeType = if device == "cuda" then "float16" else "int8";
  batchSize = if device == "cuda" then 16 else 4;

  # ── The formatter: WhisperX JSON -> a transcript a human wants to read ──
  # WhisperX's own .txt writer silently DROPS the speaker labels, which is
  # the whole point of the exercise. So we render the JSON ourselves,
  # merging consecutive segments from the same voice into single turns.
  formatter = pkgs.writeText "whisperx-to-markdown.py" ''
    import json, sys, pathlib

    src = pathlib.Path(sys.argv[1])
    dst = pathlib.Path(sys.argv[2])
    title = sys.argv[3] if len(sys.argv) > 3 else src.stem

    segments = json.loads(src.read_text()).get("segments", [])

    turns = []
    for seg in segments:
        who = seg.get("speaker") or "UNKNOWN"
        text = (seg.get("text") or "").strip()
        if not text:
            continue
        if turns and turns[-1]["speaker"] == who:
            turns[-1]["text"] += " " + text
            turns[-1]["end"] = seg.get("end", turns[-1]["end"])
        else:
            turns.append({
                "speaker": who,
                "start": seg.get("start", 0.0),
                "end": seg.get("end", 0.0),
                "text": text,
            })

    def stamp(sec):
        sec = int(sec)
        h, m, s = sec // 3600, (sec % 3600) // 60, sec % 60
        return f"{h:d}:{m:02d}:{s:02d}" if h else f"{m:d}:{s:02d}"

    speakers = sorted({t["speaker"] for t in turns})

    out = [f"# {title}", ""]
    out.append(f"*{len(turns)} turns, {len(speakers)} speaker(s): "
               + ", ".join(speakers) + "*")
    out += ["", "---", ""]
    for t in turns:
        out.append(f"**{t['speaker']}** &nbsp;`{stamp(t['start'])}`")
        out += ["", t["text"], ""]

    dst.write_text("\n".join(out))
    print(f":: {dst}  ({len(turns)} turns, {len(speakers)} speakers)")
  '';

  transcribe = pkgs.writeShellApplication {
    name = "transcribe";
    runtimeInputs = [
      pkgs.whisperx
      pkgs.ffmpeg
      pkgs.python3
    ];
    text = ''
      usage() {
        cat >&2 <<'USAGE'
      usage: transcribe [-n SPEAKERS] <audio-file> [more-files...]

        -n N   exact number of speakers, if you know it.
               Strongly recommended: left free, pyannote will
               invent a third voice out of a cough.
      USAGE
        exit 1
      }

      n_speakers=""
      while getopts ":n:h" opt; do
        case "$opt" in
          n) n_speakers="$OPTARG" ;;
          *) usage ;;
        esac
      done
      shift $((OPTIND - 1))
      [ $# -gt 0 ] || usage

      # ── The token: read at runtime, never written into the Nix store ──
      token_file="''${XDG_CONFIG_HOME:-$HOME/.config}/whisperx/token"
      if [ -n "''${HF_TOKEN:-}" ]; then
        token="$HF_TOKEN"
      elif [ -r "$token_file" ]; then
        token="$(tr -d '[:space:]' < "$token_file")"
      else
        cat >&2 <<USAGE
      !! No Hugging Face token found.

         The pyannote diarization models are gated. One-time setup:
           1. Make a free account at huggingface.co
           2. Accept the terms on the pyannote speaker-diarization model page
              (whisperx names the exact one it wants, if you pick wrong)
           3. Settings -> Access Tokens -> New token -> Read
           4. printf '%s' 'hf_xxxx' > $token_file && chmod 600 $token_file

         Used once, to fetch weights. Everything after that is offline.
      USAGE
        exit 1
      fi

      speaker_args=()
      if [ -n "$n_speakers" ]; then
        speaker_args=(--min_speakers "$n_speakers" --max_speakers "$n_speakers")
      fi

      lang_args=()
      if [ -n "${language}" ]; then
        lang_args=(--language "${language}")
      fi

      # Keep every downloaded model in one predictable, cacheable place.
      HF_HOME="''${XDG_CACHE_HOME:-$HOME/.cache}/whisperx"
      export HF_HOME
      mkdir -p "$HF_HOME"

      for f in "$@"; do
        if [ ! -f "$f" ]; then
          echo "!! no such file: $f" >&2
          continue
        fi

        dir="$(dirname "$f")"
        base="$(basename "''${f%.*}")"
        work="$(mktemp -d)"

        echo ":: $base — transcribing and diarizing"
        echo "   (the first run downloads ~3GB of models; later runs do not)"

        whisperx "$f" \
          --model ${model} \
          "''${lang_args[@]}" \
          --device ${device} \
          --compute_type ${computeType} \
          --batch_size ${toString batchSize} \
          --diarize \
          --hf_token "$token" \
          "''${speaker_args[@]}" \
          --print_progress True \
          --output_format all \
          --output_dir "$work"

        python3 ${formatter} \
          "$work/$base.json" "$dir/$base.transcript.md" "$base"

        for ext in srt json; do
          if [ -f "$work/$base.$ext" ]; then
            cp "$work/$base.$ext" "$dir/$base.$ext"
          fi
        done

        rm -rf "$work"
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
