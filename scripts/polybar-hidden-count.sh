#!/usr/bin/env bash
# polybar custom/script: how many windows are currently minimized (bspwm
# `hidden` flag). Prints nothing when none are, so the module disappears from
# the bar rather than sitting there reading "0 hidden".
#
# Left-clicking the module runs bspwm-hidden-picker (wired up in polybar.nix).
# Counted with a read loop rather than `grep -c` to keep the dependency closure
# to bspwm alone -- this runs once a second on each of four bars.

set -u

n=0
while read -r _; do
  n=$((n + 1))
done < <(bspc query -N -n .hidden.window 2>/dev/null)

[ "$n" -gt 0 ] || exit 0

printf '%%{F#EBCB8B}%s hidden%%{F-}\n' "$n"
