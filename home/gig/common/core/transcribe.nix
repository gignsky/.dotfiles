# transcribe.nix — one command, any audio file in, a speaker-labelled
# transcript out. WhisperX: faster-whisper for the words, wav2vec2 forced
# alignment for the timing, pyannote for who-spoke-when.
#
# Import from home.nix:      imports = [ ./transcribe.nix ];
#
# Usage:
#   transcribe session.mp3            # let the voices fall where they may
#   transcribe -n 4-12 session.mp3    # a RANGE — best for TTRPG (see below)
#   transcribe -n 2 interview.mp3     # an exact count, for a plain interview
#   transcribe -v session.mp3         # watch the words land as they land
#   transcribe *.mp3                  # several files, counted as it goes
#
# Writes, beside each input file:
#   <name>.transcript.md   ← the readable one, with a Voices legend at top
#   <name>.speakers        ← blank name-mapping sheet, ready to fill in
#   <name>.srt             ← subtitles, word-accurate
#   <name>.json            ← the full structured output, word-level
#
# ── ON SPEAKER COUNTS, AND WHY TTRPG IS DIFFERENT ────────────────────────
# Pyannote clusters on VOICE EMBEDDINGS — the acoustic print of a voice, not
# the identity of a person. A player doing a character voice yields a
# different embedding and lands in a different cluster. So for a table of
# five humans voicing a dozen characters, the true acoustic count is nearer
# twelve, and pinning -n 5 forces distinct voices into wrong clusters.
#
# Over-segmentation is recoverable; under-segmentation is not. Merging two
# labels is a find-and-replace. Splitting one merged label back into two
# people cannot be done without re-running the hour. So: give a generous
# RANGE (humans as floor, characters as ceiling) or none at all, and let it
# over-split. The Voices legend and the .speakers sheet exist to make the
# merging afterwards quick.

{ pkgs, ... }:

let
  # ── Knobs ────────────────────────────────────────────────────────────
  # large-v3 runs about 2.8x realtime on CPU, so a three-hour session costs
  # the better part of a working day. large-v3-turbo is roughly 4x faster
  # for a modest accuracy loss — for long informal sessions with crosstalk,
  # very likely the better trade.
  model = "large-v3";
  language = "en"; # "" to auto-detect, at the cost of a probe pass

  # nixpkgs' ctranslate2 is built WITHOUT CUDA by default, so "cuda" here
  # will fail until you either set nixpkgs.config.cudaSupport = true (add
  # the cuda-maintainers cachix first, or you will rebuild the world) or
  # override ctranslate2 alone. "cpu" always works; it is merely patient.
  device = "cpu";

  computeType = if device == "cuda" then "float16" else "int8";
  batchSize = if device == "cuda" then 16 else 4;

  langArgs = pkgs.lib.optionalString (language != "") ''--language "${language}"'';

  # ── The progress filter ──────────────────────────────────────────────
  # WhisperX emits bare "Progress: 11.11%..." lines (resetting per phase),
  # "Transcript: [a --> b] text" lines, and a good deal of logger noise.
  # This collapses all of it to one live status line, and shows the
  # transcript stream only when asked.
  progress = pkgs.writeText "transcribe-progress.py" ''
    import re, select, sys, time

    try:
        total_audio = float(sys.argv[1])
    except (IndexError, ValueError):
        total_audio = 0.0
    verbose = len(sys.argv) > 2 and sys.argv[2] == "1"
    tty = sys.stderr.isatty()

    PHASES = [("voice activity detection", "listening for speech"),
              ("Performing transcription", "transcribing"),
              ("Performing alignment", "aligning timestamps"),
              ("Performing diarization", "separating voices"),
              ("Assigning speaker", "separating voices")]
    NOISE = ("Lightning automatically upgraded", "upgrade_checkpoint",
             "TensorFloat", "degrees of freedom", "sequences.std",
             "torchaudio", "Using model:", "Loading diarization model")

    run_start = time.monotonic()
    phase, phase_start = "loading models", run_start


    def hms(s):
        s = int(max(s, 0))
        h, m, sec = s // 3600, (s % 3600) // 60, s % 60
        return f"{h}h{m:02d}m" if h else (f"{m}m{sec:02d}s" if m else f"{sec}s")


    def status(extra=""):
        line = f"   {hms(time.monotonic() - run_start):>7}  {phase}"
        if extra:
            line += f"  {extra}"
        sys.stderr.write("\r\033[2K" + line[:110] if tty else line + "\n")
        sys.stderr.flush()


    def nl():
        if tty:
            sys.stderr.write("\n")
            sys.stderr.flush()


    if total_audio:
        print(f"   {hms(total_audio)} of audio", file=sys.stderr, flush=True)
    status()

    while True:
        if not select.select([sys.stdin], [], [], 20)[0]:
            status("still working")
            continue
        line = sys.stdin.readline()
        if not line:
            break
        line = line.rstrip("\n")
        if not line.strip() or any(n in line for n in NOISE):
            continue

        m = re.search(r"Progress:\s*([0-9.]+)\s*%", line)
        if m:
            pct = float(m.group(1))
            el = time.monotonic() - phase_start
            eta = el * (100 - pct) / pct if pct > 0.5 else 0
            status(f"{pct:5.1f}%" + (f"  ~{hms(eta)} left" if eta else ""))
            continue

        t = re.match(r"Transcript:\s*\[([0-9.]+)\s*-->\s*([0-9.]+)\]\s*(.*)", line)
        if t:
            if verbose:
                nl()
                print(f"   {hms(float(t.group(1)))}  {t.group(3).strip()}",
                      file=sys.stderr, flush=True)
                status()
            continue

        hit = next((lab for key, lab in PHASES if key in line), None)
        if hit:
            if hit != phase:
                nl()
                phase, phase_start = hit, time.monotonic()
                status()
            continue

        # Swallow logger chatter and stack-trace continuation lines;
        # anything else is a real message and deserves to be seen.
        if " - INFO - " in line or " - WARNING - " in line or line.startswith("  "):
            continue

        nl()
        print(line, file=sys.stderr, flush=True)
        status()

    nl()
    print(f"   engine done in {hms(time.monotonic() - run_start)}",
          file=sys.stderr, flush=True)
  '';

  # ── The formatter ────────────────────────────────────────────────────
  # WhisperX's own .txt writer silently DROPS the speaker labels, which is
  # the whole point of the exercise. So we render the JSON ourselves:
  # consecutive segments from one voice merged into single turns, plus a
  # legend ranking each voice by speaking time with a sample utterance —
  # which is how you work out who is who when there are nine of them.
  formatter = pkgs.writeText "whisperx-to-markdown.py" ''
    import json, sys, pathlib

    src = pathlib.Path(sys.argv[1])
    dst = pathlib.Path(sys.argv[2])
    title = sys.argv[3]
    legend_path = pathlib.Path(sys.argv[4])

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
            turns.append({"speaker": who, "start": seg.get("start", 0.0),
                          "end": seg.get("end", 0.0), "text": text})


    def stamp(sec):
        sec = int(sec)
        h, m, s = sec // 3600, (sec % 3600) // 60, sec % 60
        return f"{h:d}:{m:02d}:{s:02d}" if h else f"{m:d}:{s:02d}"


    def dur(sec):
        sec = int(sec)
        m, s = sec // 60, sec % 60
        return f"{m}m{s:02d}s" if m else f"{s}s"


    stats = {}
    for t in turns:
        st = stats.setdefault(t["speaker"], {"secs": 0.0, "turns": 0, "long": ""})
        st["secs"] += max(t["end"] - t["start"], 0)
        st["turns"] += 1
        if len(t["text"]) > len(st["long"]):
            st["long"] = t["text"]

    total_secs = sum(s["secs"] for s in stats.values()) or 1
    order = sorted(stats.items(), key=lambda kv: -kv[1]["secs"])

    out = [f"# {title}", ""]
    out.append(f"*{len(turns)} turns · {len(stats)} voices · "
               f"{dur(total_secs)} of speech*")
    out += ["", "## Voices", "",
            "| Voice | Speaking | Share | Turns | Longest utterance begins |",
            "| --- | --- | --- | --- | --- |"]
    for who, st in order:
        sample = st["long"][:70].replace("|", "\\|")
        if len(st["long"]) > 70:
            sample += "…"
        out.append(f"| `{who}` | {dur(st['secs'])} | "
                   f"{100 * st['secs'] / total_secs:.0f}% | {st['turns']} "
                   f"| {sample} |")
    out += ["",
            "> Voices are acoustic, not people — a player in a character voice",
            "> appears as a separate voice. Merge by find-and-replace.",
            "", "---", ""]

    for t in turns:
        out.append(f"**{t['speaker']}** &nbsp;`{stamp(t['start'])}`")
        out += ["", t["text"], ""]

    dst.write_text("\n".join(out))
    legend_path.write_text("\n".join(f"{who}=" for who, _ in order) + "\n")
    print(f"   {dst.name} — {len(turns)} turns, {len(stats)} voices, "
          f"{dur(total_secs)} of speech")
  '';

  transcribe = pkgs.writeShellApplication {
    name = "transcribe";
    runtimeInputs = [
      pkgs.whisperx
      pkgs.ffmpeg
      pkgs.python3
      pkgs.coreutils
    ];
    text = ''
      usage() {
        cat >&2 <<'USAGE'
      usage: transcribe [-n N | -n MIN-MAX] [-v] <audio-file> [more-files...]

        -n N        exact number of distinct VOICES, if truly known
        -n MIN-MAX  a range, e.g. -n 4-12 — the right choice when people
                    put on character voices; over-splitting is recoverable,
                    merging labels afterwards is a find-and-replace
        -v          stream each segment's text as it is transcribed

      Omit -n entirely and pyannote decides for itself. For a plain
      two-person interview, -n 2 is markedly better than nothing.
      USAGE
        exit 1
      }

      n_speakers=""
      verbose=0
      while getopts ":n:vh" opt; do
        case "$opt" in
          n) n_speakers="$OPTARG" ;;
          v) verbose=1 ;;
          *) usage ;;
        esac
      done
      shift $((OPTIND - 1))
      [ $# -gt 0 ] || usage

      speaker_args=()
      case "$n_speakers" in
        "")
          : ;;
        *[!0-9-]*)
          echo "!! -n wants a number or a MIN-MAX range, got: $n_speakers" >&2
          exit 1 ;;
        *-*)
          lo="''${n_speakers%%-*}"
          hi="''${n_speakers##*-}"
          if [ -z "$lo" ] || [ -z "$hi" ]; then
            echo "!! malformed range: $n_speakers (want e.g. 4-12)" >&2
            exit 1
          fi
          speaker_args=(--min_speakers "$lo" --max_speakers "$hi") ;;
        *)
          speaker_args=(--min_speakers "$n_speakers" --max_speakers "$n_speakers") ;;
      esac

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
           3. Settings -> Access Tokens -> New token -> Read
           4. printf '%s' 'hf_xxxx' > $token_file && chmod 600 $token_file
      USAGE
        exit 1
      fi

      lang_args=( ${langArgs} )

      # Keep every downloaded model in one predictable, cacheable place.
      HF_HOME="''${XDG_CACHE_HOME:-$HOME/.cache}/whisperx"
      export HF_HOME
      mkdir -p "$HF_HOME"

      # So WhisperX's prints reach the filter the moment they happen rather
      # than sitting in a 4KB buffer for the length of the whole run.
      export PYTHONUNBUFFERED=1

      total=$#
      idx=0

      for f in "$@"; do
        idx=$((idx + 1))

        if [ ! -f "$f" ]; then
          echo "!! no such file: $f" >&2
          continue
        fi

        dir="$(dirname "$f")"
        base="$(basename "''${f%.*}")"
        work="$(mktemp -d)"

        duration="$(ffprobe -v error -show_entries format=duration \
          -of default=nw=1:nk=1 "$f" 2>/dev/null || true)"

        echo ":: [$idx/$total] $base"

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
          --output_dir "$work" 2>&1 \
          | python3 ${progress} "$duration" "$verbose"

        python3 ${formatter} \
          "$work/$base.json" \
          "$dir/$base.transcript.md" \
          "$base" \
          "$dir/$base.speakers"

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

  # SOPS secret configuration using nested path
  sops.secrets."HF_Token" = {
    path = "/home/gig/.config/whisperx/token";
  };
}
