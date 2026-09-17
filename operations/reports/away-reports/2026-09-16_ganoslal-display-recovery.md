# ganoslal display recovery — handoff

**Date:** 2026-09-16
**Branch:** `roll/111-0916-ganoslal-working-again`
**Host:** ganoslal (dual NVIDIA: RTX 3060 Ti @ `2d:00.0`, GTX 970 @ `23:00.0`, 4 monitors)

---

## TL;DR — read this first

ganoslal is currently on **26.05, kernel 6.18.51, nvidia 595.71.05**, and in that state
**the GTX 970 does not exist**: `nvidia-smi` sees one GPU, `xrandr --listproviders` shows
one provider, and output `DP-1-1` (top-center monitor) is gone entirely.

**Cause:** NVIDIA dropped Maxwell / Pascal / Volta support in the **590** driver branch.
26.05's `nvidiaPackages.stable` is 595. The GTX 970 is Maxwell.

**Fix (already committed):** `hosts/ganoslal/nvidia.nix` pins
`nvidiaPackages.legacy_580` (580.173.02 — the final branch supporting Maxwell). Verified
to **compile against kernel 6.18.51**. It has *not* been deployed yet.

The pin alone was not enough. `hosts/ganoslal/hardware-configuration.nix` also had
`boot.extraModulePackages = [ config.boot.kernelPackages.nvidia_x11 ]`. That attribute is the
**default** nvidia package for the kernel set — 595 on 26.05 — so it dragged the 595 kernel
module back into the module tree alongside the pinned 580 one, and both landed in the system
closure. Removed; the `hardware.nvidia` module already contributes the module package
matching `hardware.nvidia.package`.

Confirm the pin actually took before rebooting — this must print **only** 580:

```bash
nix-store -qR $(readlink -f /run/current-system) | grep -oE 'nvidia-x11-[0-9.]+' | sort -u
```

**Next action on ganoslal:**

```bash
cd ~/.dotfiles
git pull                 # roll/111, picks up the legacy_580 pin + this doc
just rebuild
sudo reboot
```

⚠️ **At the GRUB menu, explicitly select the newest entry.** See "GRUB will lie to you" below.

The current 3-monitor layout on screen was applied by hand with `xrandr` and **is not
persistent** — it disappears on next login.

---

## Physical layout and output names

```
[HDMI-0] [DP-1-1] [DP-1]     top row, 1920x1080@60 each (5760 wide)
         [DP-2]              bottom center, 5120x1440@144 (offset +320 to centre)
```

| Monitor | Output | GPU |
|---|---|---|
| Ultrawide 5120x1440@144 | `DP-2` | RTX 3060 Ti |
| Top left | `HDMI-0` | RTX 3060 Ti |
| Top right | `DP-1` | RTX 3060 Ti |
| Top center (LG IPS235) | `DP-1-1` | **GTX 970** (via PRIME output offload) |

**Output names are not stable.** NVIDIA derives them from RandR provider order. X defaults
to the lowest PCI bus, which picks the GTX 970 (`0x23` < `0x2d`) and renames *everything*
(the ultrawide becomes `DP-1-2`, `HDMI-0` becomes `HDMI-1-0`, and so on). `nvidia.nix` pins
`BusID "PCI:45:0:0"` (decimal `0x2d`) in `deviceSection` to keep the table above true.

Verify with `xrandr --listproviders`: `NVIDIA-0` must be the **Source Output with 7 outputs**
(the RTX). If it has 9 outputs, the pin is not in effect and every name has shifted.

> Do **not** use `grep 'PCI:\*' /var/log/X.0.log` to check this. That line reports the BIOS
> boot VGA device and will always show `35` (the GTX 970) until the BIOS primary is changed.
> It says nothing about which device X selected.

---

## Original problem and root cause (resolved)

Only 2 of 4 monitors lit, top-center mirrored onto top-right, no status bar.

X had no `BusID` pinned, so it made the GTX 970 primary. That flipped provider roles and
renamed every output. The hardcoded `xrandr` call in `sessionCommands` named `DP-2` and
`HDMI-0`, which were disconnected under the flipped naming — **a single `xrandr` call naming
an absent output fails as a whole**, so no layout was applied at all. Only the guarded
`xrandr --output DP-1-1 --auto` survived, landing `DP-1-1` on top of `DP-1` at `+0+0`.
That was the "mirroring".

`/tmp/xrandr-init.log` is the record: a 4-monitor entry on 2026-03-16, 2-monitor entries after.

The layout now lives in `sessionCommands` but is **guarded** — it only fires once all four
outputs are confirmed connected, and otherwise lays connected outputs out left-to-right
rather than stacking them at `+0+0`. That fallback is working correctly right now on 595.

### Other findings, all fixed

- **`DP-1-1` needs explicit enabling.** It reports connected with a full mode list, but X
  never assigns it a CRTC on its own. It stays dark unless something sets a mode. This is
  why it works in BIOS and at the login screen (kernel framebuffer) but not in X.
- **Polybar was never broken, just disabled** — `# ./polybar.nix` was commented out in
  `home/gig/common/optional/bspwm.nix` since `066fb2e1` ("removed picom and polybar, temp").
  Re-enabled, and given a real per-monitor launch loop; the old `polybar main &` only ever
  produced one bar on the primary output.
- **Polybar's unit has a minimal PATH** (`Environment=PATH` = polybar + `/run/wrappers/bin`).
  `grep`/`cut` must be referenced by absolute store path or the loop silently finds no
  monitors, the script exits 0, and the service goes straight back to inactive.
- **Wallpapers are Git LFS.** `*.png` is LFS-tracked. A plain `git pull` on a fresh host
  leaves 133-byte pointer files, and nix copies those into the store verbatim — feh was
  being handed a text file, not an image. `git lfs pull` is now part of `just pull`.
  **Gotcha:** nix caches the flake source, so after `git lfs pull` you must also
  `rm -rf ~/.cache/nix` before the real bytes reach the store.
- **XFCE was tried and abandoned** — `xfce4-session` blanks every display on this dual-GPU
  setup. Not imported. `hosts/common/optional/xfce.nix` still exists if anyone wants to retry.
- **`font-awesome` was missing** from `fonts.packages`, so polybar's icon glyphs silently
  fell back to Cartograph CF. Added. 26.05 ships font-awesome 7.2.0, which matches the
  "Font Awesome 7" names roll/111's polybar config asks for.

---

## GRUB will lie to you

`hosts/ganoslal/default.nix` sets `default = "saved"` with `GRUB_SAVEDEFAULT=true`. GRUB
boots the **last-booted** entry, not the newest one.

This already caused a false alarm: after a `just rebuild`, a reboot landed on a *stale*
25.11 generation that predated the layout fix. The symptoms looked identical to the original
bug (ultrawide at 1920x1080, top-center black) and were easy to misread as "the upgrade broke
it". It hadn't — that generation simply never had the fix.

**When rebooting to apply a rebuild, select the newest entry by hand.** Worth considering
whether `default = "saved"` earns its place here, since it makes "reboot to apply" unreliable.

---

## Why the screens went black during `just switch`

Three separate things, in order of severity:

1. **nvidia 595 drops the GTX 970** — the real problem. Fixed by the `legacy_580` pin.
2. **Kernel 6.12.68 → 6.18.51.** The new nvidia modules are built for 6.18 and cannot load
   into the running 6.12 kernel. X cannot come back until a reboot. Normal for a kernel bump.
3. **Stale dbus.** dbus had been running since the pre-switch boot and never reloaded, so it
   had no knowledge of the new `org.freedesktop.DisplayManager` policy. LightDM crash-looped
   on `Failed to use bus name org.freedesktop.DisplayManager, do you have appropriate
   permissions?` — which reads like a permissions bug but is just a stale bus. A reboot
   clears it.

Only #1 needs a config change. #2 and #3 are inherent to switching and resolve on reboot.

---

## Commits on `roll/111-0916-ganoslal-working-again`

| Commit | What |
|---|---|
| `a557a45d` | Pin RTX as X primary (`BusID "PCI:45:0:0"`); hand layout to XFCE (later reverted) |
| `d9416f14` | Restore the monitor layout in `sessionCommands`, guarded against missing outputs |
| `e5ae183c` | Drop XFCE; re-enable polybar per-monitor; restore wallpaper |
| `3c1fdd97` | polybar: absolute paths for grep/cut in the launch script |
| `1879f18e` | Add `font-awesome`; `git lfs pull` in `just pull` |
| `c954e8a6` | Merge `ganoslal/2-fixing-displays` into roll/111 (26.05 base) |
| *(this one)* | Pin `nvidiaPackages.legacy_580`; this handoff doc |

### Merge resolution notes (`c954e8a6`)

Two conflicts, both resolved toward roll/111:

- `hosts/common/optional/bspwm.nix` — took roll/111's LightDM + autoLogin. Keeping the `ly`
  side would have left **both** display managers enabled, since the `lightdm` block below the
  conflict was unconflicted.
- `hosts/ganoslal/default.nix` — comment-only clash over the xfce import.

Two things auto-merge got right that would have been easy to lose:

- **`nvidia.nix` resolved to the ganoslal/2 version.** roll/111's copy still sets
  `prime.amdgpuBusId` for an AMD GPU this machine does not have, and `open = true`, which the
  GTX 970 cannot use. Taking roll/111's side would have re-broken the displays.
- **The GRUB block survived.** roll/111 switches ganoslal to `systemd-boot`, which would have
  dropped the `useOSProber` Windows entry.

---

## Open items

1. **Deploy the `legacy_580` pin** (the next action at the top of this doc). Until then
   ganoslal is a 3-monitor machine.
2. **Fleet check before roll/111 goes further.** Any other host driving a Maxwell, Pascal or
   Volta card will hit the same 595 wall. merlin and spacedock still use
   `nvidiaPackages.stable`.
3. **`opencode-auth` secret.** `home/gig/common/*/opencode.nix` declares
   `sops.secrets."opencode-auth/${hostname}"`, but nix-secrets commit `2c2d96c`
   ("updated secrets", 2026-07-21) **removed** the `opencode-auth` key. sops-nix then fails
   activation, which is what made `just home` exit non-zero even though the build and
   activation both succeeded. On roll/111 this is incidentally resolved for ganoslal because
   `opencode.nix` moved from `common/core/` (auto-scanned) to `common/optional/`. **Any host
   that still imports it will keep failing** — either re-add the key to nix-secrets or drop
   the declaration.
4. **`top_padding = 0`** in `home/gig/common/optional/bspwm.nix`, on the assumption bspwm
   honours polybar's `_NET_WM_STRUT_PARTIAL`. If windows end up *behind* the bar rather than
   below it, set it back to `30`.
5. **PRIME offload cost.** `DP-1-1` is driven by the GTX 970 as a RandR output sink, so its
   framebuffer is copied over PCIe. Fine for a static 1080p panel, poor for anything moving.
   The ultrawide is native on the RTX, which is what matters.
6. **`youtube-music` → `pear-desktop`** rename warning on 26.05 (`home/gig/ganoslal.nix`,
   and the bspwm window rules reference the old class). Still works via alias.

---

## Verification commands

Run after any change. All work over SSH with `DISPLAY=:0`.

```bash
# 1. Both GPUs present — if only one, you are on a 590+ driver
nvidia-smi --query-gpu=index,name,pci.bus_id --format=csv

# 2. RTX is the source provider. Must be NVIDIA-0 with 7 outputs,
#    plus an NVIDIA-G0 sink with 9. One provider only = GTX 970 unsupported.
DISPLAY=:0 xrandr --listproviders

# 3. Four monitors at four DISTINCT origins. Two sharing +0+0 is the mirroring bug.
DISPLAY=:0 xrandr --listmonitors

# 4. Ultrawide at native res and rate (look for 144.00 with a '*')
DISPLAY=:0 xrandr --query | grep -A2 '^DP-2 connected'

# 5. bspwm desktops bound to all four monitors
for m in $(bspc query -M --names); do
  printf "%s: " "$m"; bspc query -D -m "$m" --names | tr '\n' ' '; echo
done
# expect: DP-2: I II III IV XI / HDMI-0: V VI / DP-1-1: VII VIII / DP-1: IX X

# 6. One polybar per monitor, tray only on the primary
for p in $(pgrep polybar); do
  tr '\0' '\n' < /proc/$p/environ | grep -E '^(MONITOR|TRAY_POSITION)='
done

# 7. Wallpaper actually applied (feh writes this only on success)
cat ~/.fehbg

# 8. What the session commands actually produced
tail -20 /tmp/xrandr-init.log
```

### Ordering gotcha

`sessionCommands` runs before the window manager, so monitors exist by the time `bspwmrc`
assigns desktops. If you fix the layout by hand *after* login, `DP-1-1` will carry a default
desktop named `Desktop` and polybar will have one bar too few. Re-sync with:

```bash
bspc wm -r                              # re-runs bspwmrc: desktops + wallpaper
systemctl --user restart polybar.service # re-runs the per-monitor launch loop
```

---

## Recovery

SSH stays up even with X completely broken — it is the safety net throughout.

```bash
sudo nixos-rebuild switch --rollback   # previous generation
```

Or pick an older entry at GRUB (`configurationLimit = 20`). Known-good reference points:

| Generation | Store path prefix | Notes |
|---|---|---|
| 33 | `3r3ilxls…` | 26.05, nvidia 595 — **3 monitors only**, GTX 970 absent |
| — | `h8x7mmq0…` | 26.05 + nvidia 580 pin — built and staged, **not yet switched to** |
| — | `n66bbvnr…` | 25.11 with the guarded layout — last known 4-monitor-good |
| — | `7wdcr9fl…` | 25.11, BusID pin but **no layout** — looks broken, is stale |
