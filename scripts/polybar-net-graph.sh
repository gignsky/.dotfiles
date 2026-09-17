#!/usr/bin/env bash
# Network throughput sparkline for polybar (custom/script with tail = true).
#
# Prints one line per second, forever:
#   NET ▁▂▅▇▃▁▁▂ ↓ 4.2M ↑ 318K
#
# polybar has no native graph type, so the history lives here: an 8-slot ring of
# the combined rate, each slot mapped onto U+2581..U+2588. Those blocks and the
# ↓↑ arrows are all in DejaVu Sans (font-0 in polybar.nix) -- no Font Awesome.
#
# PATH: this runs under the polybar systemd unit, whose Environment=PATH is just
# the polybar package and /run/wrappers/bin (see the NOTE in polybar.nix). The
# makeScriptPackage wrapper in pkgs/scripts.nix prepends this script's declared
# dependencies, so `sleep` resolves -- but nothing here may assume anything else
# is on PATH. Everything else below is a bash builtin or a read from /sys.

set -u

SLOTS=8          # sparkline width
INTERVAL=1       # seconds between samples
FLOOR=65536      # 64 KiB/s -- anything below this sits at the lowest block
ACCENT='#88C0D0' # Nord frost, matches the other module prefixes
GRAPH='#A3BE8C'  # Nord green
DIM='#4C566A'

BLOCKS=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █)

# The scale is deliberately ABSOLUTE (log4 from FLOOR: 64K 256K 1M 4M 16M 64M
# 256M+) rather than normalised against a rolling window max. A rolling max
# makes an idle link's background chatter fill the whole graph, so a 100 KiB/s
# blip looks identical to a saturated gigabit link. With a fixed scale the bar
# height means the same thing from one glance to the next.
# Sets LVL rather than echoing: this is called SLOTS times a second on each of
# four bars, and a command substitution per slot is a subshell per slot.
level() {
  local v=$1 bound=$FLOOR
  LVL=0
  while [ "$LVL" -lt 7 ] && [ "$v" -ge "$bound" ]; do
    bound=$((bound * 4))
    LVL=$((LVL + 1))
  done
}

# Bytes/sec -> short human string, integer arithmetic only (no bc, no awk).
# Carries tenths through the divisions so values under 10 keep one decimal:
# 942K, 4.2M, 118M, 1.1G.
human() {
  local t=$(($1 * 10)) i=0
  local -a units=(B K M G T)
  while [ "$t" -ge 10240 ] && [ "$i" -lt 4 ]; do
    t=$((t / 1024))
    i=$((i + 1))
  done
  if [ "$t" -lt 100 ]; then
    printf '%d.%d%s' $((t / 10)) $((t % 10)) "${units[i]}"
  else
    printf '%d%s' $((t / 10)) "${units[i]}"
  fi
}

# Re-detected every tick so a cable pull, a USB NIC appearing, or a different
# host entirely just works -- ganoslal is enp39s0 today, merlin is wlp2s0, and
# hardware-configuration.nix has both commented out.
active_iface() {
  local dev state
  for dev in /sys/class/net/*; do
    [ -e "$dev/statistics/rx_bytes" ] || continue
    [ "${dev##*/}" = lo ] && continue
    read -r state <"$dev/operstate" 2>/dev/null || continue
    [ "$state" = up ] || continue
    printf '%s' "${dev##*/}"
    return 0
  done
  return 1
}

hist=()
for ((i = 0; i < SLOTS; i++)); do hist+=(0); done

prev_if=''
prev_rx=-1
prev_tx=-1

while :; do
  iface=$(active_iface) || iface=''

  if [ -n "$iface" ]; then
    read -r rx <"/sys/class/net/$iface/statistics/rx_bytes" 2>/dev/null || rx=0
    read -r tx <"/sys/class/net/$iface/statistics/tx_bytes" 2>/dev/null || tx=0
  else
    rx=0
    tx=0
  fi

  # Only diff against the previous sample if it came from the same interface --
  # otherwise a switch between NICs reads as one enormous spike.
  if [ "$iface" = "$prev_if" ] && [ "$prev_rx" -ge 0 ]; then
    drx=$(((rx - prev_rx) / INTERVAL))
    dtx=$(((tx - prev_tx) / INTERVAL))
    [ "$drx" -lt 0 ] && drx=0 # counter reset
    [ "$dtx" -lt 0 ] && dtx=0
  else
    drx=0
    dtx=0
  fi

  prev_if=$iface
  prev_rx=$rx
  prev_tx=$tx

  hist=("${hist[@]:1}" "$((drx + dtx))")

  spark=''
  for v in "${hist[@]}"; do
    level "$v"
    spark+="${BLOCKS[LVL]}"
  done

  if [ -n "$iface" ]; then
    printf '%%{F%s}NET%%{F-} %%{F%s}%s%%{F-} ↓ %s ↑ %s\n' \
      "$ACCENT" "$GRAPH" "$spark" "$(human "$drx")" "$(human "$dtx")"
  else
    printf '%%{F%s}NET%%{F-} %%{F%s}down%%{F-}\n' "$ACCENT" "$DIM"
  fi

  sleep "$INTERVAL"
done
