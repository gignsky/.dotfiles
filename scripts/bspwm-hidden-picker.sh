#!/usr/bin/env bash
# rofi picker for minimized (bspwm `hidden` flag) windows.
#
# super + m hides a window; without this there was no way to see what had been
# hidden -- super + u only reaches the most recent one and super + shift + u
# restores everything at once. Bound to super + shift + m and to a left click on
# polybar's `hidden` module, so it must not assume anything about PATH (the
# polybar unit's is minimal). makeScriptPackage supplies the dependencies.

set -u

mapfile -t ids < <(bspc query -N -n .hidden.window 2>/dev/null)
[ "${#ids[@]}" -gt 0 ] || exit 0

labels=()
for id in "${ids[@]}"; do
  [ -n "$id" ] || continue
  # xdotool parses the 0x... id fine, but fall back rather than showing a blank row.
  title=$(xdotool getwindowname "$id" 2>/dev/null)
  [ -n "$title" ] || title='(untitled)'
  # Titles alone are often useless -- a hidden terminal is just "~" -- so lead
  # with the class, trimmed to its last dot-segment
  # (org.wezfurlong.wezterm -> wezterm).
  class=$(xdotool getwindowclassname "$id" 2>/dev/null)
  class=${class##*.}
  desk=$(bspc query -D -n "$id" --names 2>/dev/null)
  labels+=("${desk:-?}  ${class:-?}  —  $title")
done

[ "${#labels[@]}" -gt 0 ] || exit 0

# -format i returns the selected row's 0-based index, so the id never has to be
# parsed back out of the label; -no-custom keeps a typed string from producing
# an index that does not exist.
sel=$(printf '%s\n' "${labels[@]}" |
  rofi -dmenu -i -no-custom -format i -p 'restore hidden window')
[ -n "$sel" ] || exit 0

# -f focuses, which also switches to whichever desktop the window lives on.
bspc node "${ids[$sel]}" -g hidden=off -f
