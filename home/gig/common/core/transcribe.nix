# transcribe.nix — one command, audio in, a speaker-labelled transcript out.
# WhisperX: faster-whisper for the words, wav2vec2 forced alignment for the
# timing, pyannote for who-spoke-when.
#
# Import from home.nix:      imports = [ ./transcribe.nix ];
#
# TWO MODES
#
#   Separate sessions — each file transcribed on its own, each into its own
#   session directory:
#       transcribe s1.mp3 s2.mp3 s3.mp3
#     ->  s1/s1.transcript.md   s2/s2.transcript.md   s3/s3.transcript.md
#
#   One session in clips — -c welds them into one continuous recording FIRST,
#   then transcribes once:
#       transcribe -c "7.28.26 - "*.mp3
#     ->  7.28.26/7.28.26.transcript.md   (+ a Clips table of offsets)
#
#   Why -c matters: speaker labels cannot be shared across separate runs.
#   Transcribe three clips singly and SPEAKER_00 in clip one has no relation
#   to SPEAKER_00 in clip two. Welded first, one clustering covers the whole
#   session and the labels mean something end to end.
#
# EACH SESSION DIRECTORY HOLDS
#   <name>.transcript.md   ← the readable one: Clips, Voices, then the talk
#   <name>.speakers        ← blank name-mapping sheet, ready to fill in
#   <name>.srt  <name>.json
#
# FLAGS
#   -n N        exact number of distinct VOICES, if truly known
#   -n MIN-MAX  a range, e.g. -n 5-14 — the right choice for TTRPG
#   -c          combine all inputs into one session before transcribing
#   -o NAME     name the session (default: common prefix of the filenames)
#   -k          keep the combined audio file (default: deleted after)
#   -v          stream each segment's text as it is transcribed
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
# over-split. The Voices legend and the .speakers sheet make the merging
# afterwards quick.

{ pkgs, ... }:

let
  # ── Knobs ────────────────────────────────────────────────────────────
  # large-v3-turbo: roughly 4x faster than large-v3 for a modest accuracy
  # loss, mostly on rare proper nouns. For multi-hour sessions with
  # crosstalk and character voices, decisively the better trade — large-v3
  # ran ~2.8x realtime, which is a whole working day for a three-hour game.
  model = "large-v3-turbo";
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
  # consecutive segments from one voice merged into single turns, a Clips
  # table when several were welded together, and a Voices legend ranking
  # each voice by speaking time with a sample utterance — which is how you
  # work out who is who when there are eleven of them.
  formatter = pkgs.writeText "whisperx-to-markdown.py" ''
    import json, sys, pathlib

    src = pathlib.Path(sys.argv[1])
    dst = pathlib.Path(sys.argv[2])
    title = sys.argv[3]
    legend_path = pathlib.Path(sys.argv[4])
    clips_path = (pathlib.Path(sys.argv[5])
                  if len(sys.argv) > 5 and sys.argv[5] else None)

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
        h, m, s = sec // 3600, (sec % 3600) // 60, sec % 60
        return f"{h}h{m:02d}m" if h else (f"{m}m{s:02d}s" if m else f"{s}s")


    stats = {}
    for t in turns:
        st = stats.setdefault(t["speaker"],
                              {"secs": 0.0, "turns": 0, "long": ""})
        st["secs"] += max(t["end"] - t["start"], 0)
        st["turns"] += 1
        if len(t["text"]) > len(st["long"]):
            st["long"] = t["text"]

    total_secs = sum(s["secs"] for s in stats.values()) or 1
    order = sorted(stats.items(), key=lambda kv: -kv[1]["secs"])

    out = [f"# {title}", ""]
    out.append(f"*{len(turns)} turns · {len(stats)} voices · "
               f"{dur(total_secs)} of speech*")

    if clips_path and clips_path.exists():
        rows = [ln.split("\t", 1) for ln in
                clips_path.read_text().splitlines() if "\t" in ln]
        if len(rows) > 1:
            out += ["", "## Clips", "", "| # | Begins at | Clip |",
                    "| --- | --- | --- |"]
            for i, (off, name) in enumerate(rows, 1):
                out.append(f"| {i} | `{stamp(float(off))}` | {name} |")
            out += ["", "*Offsets are approximate to within a second or so —"
                    " container padding accumulates across joins.*"]

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
      usage: transcribe [-c] [-n N|MIN-MAX] [-o NAME] [-k] [-v] <audio>...

        -n N        exact number of distinct VOICES, if truly known
        -n MIN-MAX  a range, e.g. -n 5-14 — right when people put on
                    character voices; over-splitting is recoverable,
                    merging labels afterwards is a find-and-replace
        -c          COMBINE all inputs into one session first, then
                    transcribe once. Use for clips of a single sitting:
                    speaker labels cannot be shared across separate runs.
        -o NAME     name the session (default: common filename prefix)
        -k          keep the combined audio (default: deleted after)
        -v          stream each segment's text as it is transcribed

      Each transcription lands in its own directory named for the session.
      USAGE
        exit 1
      }

      # Longest common prefix of the basenames — so three clips named
      # "7.28.26 - 1", "- 2", "- 3" yield a session called "7.28.26".
      common_name() {
        local first="" cand="" f b i
        for f in "$@"; do
          b="$(basename "''${f%.*}")"
          if [ -z "$first" ]; then
            first="$b"; cand="$b"; continue
          fi
          i=0
          while [ "$i" -lt "''${#cand}" ] && [ "$i" -lt "''${#b}" ] \
            && [ "''${cand:$i:1}" = "''${b:$i:1}" ]; do
            i=$((i + 1))
          done
          cand="''${cand:0:$i}"
        done
        cand="$(printf '%s' "$cand" | sed -E 's/[[:space:]_.-]+$//')"
        if [ -z "$cand" ]; then
          cand="$(basename "''${1%.*}")-combined"
        fi
        printf '%s' "$cand"
      }

      n_speakers=""
      combine=0
      keep=0
      verbose=0
      outname=""
      while getopts ":n:o:ckvh" opt; do
        case "$opt" in
          n) n_speakers="$OPTARG" ;;
          o) outname="$OPTARG" ;;
          c) combine=1 ;;
          k) keep=1 ;;
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
            echo "!! malformed range: $n_speakers (want e.g. 5-14)" >&2
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

      # ── One transcription: audio in, a populated session directory out ──
      # $1 audio  $2 session dir  $3 session name  $4 clips manifest or ""
      run_one() {
        local audio="$1" outdir="$2" name="$3" clips="''${4:-}"
        local abase work duration ext

        abase="$(basename "''${audio%.*}")"
        mkdir -p "$outdir"
        work="$(mktemp -d)"

        duration="$(ffprobe -v error -show_entries format=duration \
          -of default=nw=1:nk=1 "$audio" 2>/dev/null || true)"

        whisperx "$audio" \
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
          "$work/$abase.json" \
          "$outdir/$name.transcript.md" \
          "$name" \
          "$outdir/$name.speakers" \
          "$clips"

        for ext in srt json; do
          if [ -f "$work/$abase.$ext" ]; then
            cp "$work/$abase.$ext" "$outdir/$name.$ext"
          fi
        done

        rm -rf "$work"
      }

      if [ "$combine" -eq 1 ]; then
        # ── One session, delivered in clips ──────────────────────────────
        # Natural sort, so "- 10" follows "- 9" rather than "- 1".
        mapfile -t clips_in < <(printf '%s\n' "$@" | sort -V)

        for f in "''${clips_in[@]}"; do
          if [ ! -f "$f" ]; then
            echo "!! no such file: $f" >&2
            exit 1
          fi
        done

        name="$outname"
        if [ -z "$name" ]; then
          name="$(common_name "''${clips_in[@]}")"
        fi
        outdir="$(dirname "''${clips_in[0]}")/$name"
        mkdir -p "$outdir"

        combined="$outdir/$name.combined.flac"
        manifest="$outdir/$name.clips.tsv"

        echo ":: welding ''${#clips_in[@]} clips into one session: $name"

        # The concat FILTER, not the concat demuxer — it decodes each input
        # and so tolerates clips that differ in codec, sample rate, or
        # channel count, which recordings from mixed sources usually do.
        # 16 kHz mono is exactly what Whisper and pyannote consume anyway.
        ff_args=()
        filter=""
        i=0
        : > "$manifest"
        offset=0
        for f in "''${clips_in[@]}"; do
          ff_args+=(-i "$f")
          filter+="[$i:a]"
          i=$((i + 1))
          printf '%s\t%s\n' "$offset" "$(basename "$f")" >> "$manifest"
          d="$(ffprobe -v error -show_entries format=duration \
            -of default=nw=1:nk=1 "$f" 2>/dev/null || echo 0)"
          offset="$(python3 -c "print(f'{$offset + ($d or 0):.3f}')")"
        done
        filter+="concat=n=$i:v=0:a=1[out]"

        ffmpeg -v error -y "''${ff_args[@]}" -filter_complex "$filter" \
          -map "[out]" -ar 16000 -ac 1 -c:a flac "$combined"

        echo ":: $name"
        run_one "$combined" "$outdir" "$name" "$manifest"

        if [ "$keep" -eq 0 ]; then
          rm -f "$combined"
        else
          echo "   kept $combined"
        fi
      else
        # ── Separate sessions, one directory apiece ──────────────────────
        total=$#
        idx=0
        for f in "$@"; do
          idx=$((idx + 1))
          if [ ! -f "$f" ]; then
            echo "!! no such file: $f" >&2
            continue
          fi
          name="$outname"
          if [ -z "$name" ]; then
            name="$(basename "''${f%.*}")"
          fi
          outdir="$(dirname "$f")/$name"
          echo ":: [$idx/$total] $name"
          run_one "$f" "$outdir" "$name" ""
        done
      fi
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
