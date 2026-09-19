#!/usr/bin/env bash
# dns-probe — capture intermittent DNS resolution stalls.
#
# Context: git push/pull to github.com intermittently stalls ~10s on merlin. The stall
# was located (via `ssh -vvv`) between "resolving github.com" and "Connecting to", i.e.
# inside name resolution, but it does not reproduce on demand. This probe runs on a timer
# and records per-layer timings so that when a stall does happen, the log shows WHICH
# layer was slow rather than leaving us to guess.
#
# See engineering/enhancement-protocols/ and the DNS notes in docs/ for background.
#
# Layers timed independently:
#   1. getaddrinfo  (`getent ahosts`)  — the path ssh/git actually use
#   2. gethostbyname(`getent hosts`)   — legacy path; also catches search-domain poisoning
#   3. each nameserver in resolv.conf, queried directly — isolates a bad upstream
#   4. git ls-remote                   — the end-to-end symptom (optional, --with-git)
#
# Exit status is always 0: this is a monitor, not a check. It must never fail a timer.

set -uo pipefail

TARGET="${DNS_PROBE_TARGET:-github.com}"
LOG="${DNS_PROBE_LOG:-/var/log/dns-probe/dns-probe.log}"
# Anything slower than this (milliseconds) is treated as an event worth detailing.
THRESHOLD_MS="${DNS_PROBE_THRESHOLD_MS:-1000}"
WITH_GIT=0
GIT_REPO="${DNS_PROBE_GIT_REPO:-}"

usage() {
  cat <<EOF
Usage: dns-probe [options]

  --target HOST     hostname to probe            (default: ${TARGET})
  --log PATH        log file                     (default: ${LOG})
  --threshold MS    slow-event threshold in ms   (default: ${THRESHOLD_MS})
  --with-git        also time 'git ls-remote' end-to-end
  --repo PATH       repo to run git ls-remote in (implies --with-git)
  --stdout          write to stdout instead of the log file
  -h, --help        this help

Environment overrides: DNS_PROBE_TARGET, DNS_PROBE_LOG, DNS_PROBE_THRESHOLD_MS,
DNS_PROBE_GIT_REPO
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --target)    TARGET="$2"; shift 2 ;;
    --log)       LOG="$2"; shift 2 ;;
    --threshold) THRESHOLD_MS="$2"; shift 2 ;;
    --with-git)  WITH_GIT=1; shift ;;
    --repo)      GIT_REPO="$2"; WITH_GIT=1; shift 2 ;;
    --stdout)    LOG=""; shift ;;
    -h|--help)   usage; exit 0 ;;
    *)           echo "dns-probe: unknown option '$1'" >&2; usage >&2; exit 0 ;;
  esac
done

now_ms() { date +%s%3N; }

# Time a command. Sets two globals rather than printing, because callers need BOTH the
# elapsed time and the command's output -- returning via $(...) would run this in a
# subshell and discard any global assignment.
#   ELAPSED_MS : wall-clock milliseconds
#   REPLY_OUT  : first line of the command's stdout
ELAPSED_MS=0
REPLY_OUT=""
time_it() {
  local start end
  start=$(now_ms)
  REPLY_OUT=$("$@" 2>/dev/null | head -1)
  end=$(now_ms)
  ELAPSED_MS=$(( end - start ))
}

# Query one nameserver directly for an A record. Prefers dig; falls back to host so the
# probe still reports something useful if dnsutils is unavailable.
# shellcheck disable=SC2329  # invoked indirectly, as `time_it query_ns ...`
if command -v dig >/dev/null 2>&1; then
  query_ns() { dig +time=5 +tries=1 +short "@$1" "$2" A; }
elif command -v host >/dev/null 2>&1; then
  query_ns() { host -W 5 -t A "$2" "$1" 2>/dev/null | awk '/has address/ {print $NF; exit}'; }
else
  query_ns() { return 1; }
fi

emit() {
  if [ -n "$LOG" ]; then
    printf '%s\n' "$*" >>"$LOG"
  else
    printf '%s\n' "$*"
  fi
}

if [ -n "$LOG" ]; then
  mkdir -p "$(dirname "$LOG")" 2>/dev/null || true
  if ! touch "$LOG" 2>/dev/null; then
    echo "dns-probe: cannot write $LOG, falling back to stdout" >&2
    LOG=""
  fi
fi

TS=$(date -Is)

# --- layer 1 & 2: the two libc resolver paths -------------------------------------
time_it getent ahosts "$TARGET"; GAI_MS=$ELAPSED_MS;  GAI_OUT="$REPLY_OUT"
time_it getent hosts  "$TARGET"; GHBN_MS=$ELAPSED_MS; GHBN_OUT="$REPLY_OUT"

# --- layer 3: each configured nameserver, queried directly ------------------------
# Re-read resolv.conf every run: it is rewritten by resolvconf as the network changes,
# and the nameserver list has been observed to differ between runs on this host.
NAMESERVERS=$(awk '/^nameserver/ {print $2}' /etc/resolv.conf 2>/dev/null)
NS_PARTS=""
NS_WORST=0
for ns in $NAMESERVERS; do
  time_it query_ns "$ns" "$TARGET"
  ans="$REPLY_OUT"
  [ -z "$ans" ] && ans="NOANSWER"
  NS_PARTS="${NS_PARTS} ns[${ns}]=${ELAPSED_MS}ms/${ans}"
  [ "$ELAPSED_MS" -gt "$NS_WORST" ] && NS_WORST=$ELAPSED_MS
done

# --- layer 4: end-to-end symptom --------------------------------------------------
GIT_MS=-1
if [ "$WITH_GIT" = "1" ]; then
  if [ -n "$GIT_REPO" ] && [ -d "$GIT_REPO" ]; then
    time_it git -C "$GIT_REPO" ls-remote origin
  else
    time_it git ls-remote "https://github.com/gignsky/.dotfiles.git"
  fi
  GIT_MS=$ELAPSED_MS
fi

# --- classify ---------------------------------------------------------------------
WORST=$GAI_MS
[ "$GHBN_MS" -gt "$WORST" ] && WORST=$GHBN_MS
[ "$NS_WORST" -gt "$WORST" ] && WORST=$NS_WORST
[ "$GIT_MS" -gt "$WORST" ] && WORST=$GIT_MS

LEVEL="ok"
[ "$WORST" -ge "$THRESHOLD_MS" ] && LEVEL="SLOW"

LINE="${TS} ${LEVEL} target=${TARGET} getaddrinfo=${GAI_MS}ms gethostbyname=${GHBN_MS}ms"
LINE="${LINE}${NS_PARTS}"
[ "$GIT_MS" -ge 0 ] && LINE="${LINE} git_ls_remote=${GIT_MS}ms"
emit "$LINE"

# On a slow event, record the detail needed to tell the layers apart after the fact.
if [ "$LEVEL" = "SLOW" ]; then
  emit "  ├─ getaddrinfo  -> ${GAI_OUT:-<empty>}"
  emit "  ├─ gethostbyname-> ${GHBN_OUT:-<empty>}"
  emit "  ├─ resolv.conf  : $(tr '\n' ';' </etc/resolv.conf 2>/dev/null)"
  emit "  └─ interpretation:"
  if [ "$NS_WORST" -ge "$THRESHOLD_MS" ]; then
    emit "     a configured nameserver was itself slow -> upstream/recursion problem"
  elif [ "$GAI_MS" -ge "$THRESHOLD_MS" ] || [ "$GHBN_MS" -ge "$THRESHOLD_MS" ]; then
    emit "     nameservers answered fast but libc was slow -> local resolver/nsncd/nsswitch"
  else
    emit "     resolution was fast but git was slow -> network path or GitHub, not DNS"
  fi
fi

exit 0
