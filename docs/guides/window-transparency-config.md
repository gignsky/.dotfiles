# Window Transparency Configuration Guide

## Overview
Window transparency is managed by **picom** compositor through home-manager configuration.

## Configuration File
**Location:** `home/gig/common/optional/picom.nix`

## Current Settings (As of 2026-02-27)

### Opacity Levels
- **Active windows (focused):** 71% opaque (0.71)
- **Inactive windows (unfocused):** 64% opaque (0.64)
- **Window frames/borders:** 68% opaque (0.68)

### Per-Application Overrides
- **Web browsers** (Firefox, Chromium): 100% opaque (no transparency)
- **Video players** (mpv, vlc): 100% opaque (no transparency)
- **Terminal** (WezTerm): 71% opaque (matches active windows)
- **Launcher** (Rofi): 64% opaque (matches inactive windows)
- **Code editors** (Code/VSCode): 71% opaque (matches active windows)

### Other Features
- **Blur effects:** DISABLED (for performance)
- **Fade animations:** Enabled (smooth transitions)
- **Drop shadows:** Enabled (75% opacity, 12px radius)

## How to Adjust Transparency

### Method 1: Edit Configuration File
1. Open the config file:
   ```bash
   $EDITOR home/gig/common/optional/picom.nix
   ```

2. Modify the opacity values (0.0 = fully transparent, 1.0 = fully opaque):
   ```nix
   active-opacity = 0.71;    # Focused windows
   inactive-opacity = 0.64;  # Unfocused windows
   frame-opacity = 0.68;     # Window borders
   ```

3. Add/modify per-application rules:
   ```nix
   opacity-rule = [
     "100:class_g = 'Firefox'"  # Full opacity
     "80:class_g = 'Alacritty'" # 80% opaque
     # Add more rules as needed
   ];
   ```

4. Rebuild home-manager:
   ```bash
   just home-bare
   ```

5. Restart picom (if it doesn't auto-reload):
   ```bash
   pkill picom
   systemctl --user restart picom.service
   ```

### Method 2: Quick Opacity Changes
To quickly test different opacity values without rebuilding:

```bash
# Kill current picom
pkill picom

# Test with different opacity (e.g., 0.85 for active, 0.75 for inactive)
picom --backend glx --active-opacity 0.85 --inactive-opacity 0.75 &
```

**Note:** Changes made this way are temporary and will be lost on next home-manager rebuild.

### Finding Application Class Names
To find the class name of a window (for per-app rules):

```bash
# Method 1: Use xprop
xprop | grep WM_CLASS
# Then click on the window you want to identify

# Method 2: Use xdotool
xdotool selectwindow getwindowclassname
```

## Troubleshooting

### Picom Won't Start
**Error:** "Another composite manager is already running"

**Solution:**
```bash
# Kill any existing picom processes
pkill picom

# Restart the service
systemctl --user restart picom.service

# Check status
systemctl --user status picom.service
```

### Changes Not Taking Effect
1. Verify the config file was updated:
   ```bash
   cat home/gig/common/optional/picom.nix | grep opacity
   ```

2. Rebuild home-manager:
   ```bash
   just home-bare
   ```

3. Restart picom:
   ```bash
   systemctl --user restart picom.service
   ```

### Transparency Too Low (Hard to Read)
If windows are too transparent:
- Increase the opacity values (closer to 1.0)
- Add specific applications to opacity-rule with higher values
- Consider different values for different application types

### Performance Issues
If experiencing lag or stuttering:
1. Disable shadows:
   ```nix
   shadow = false;
   ```

2. Disable fading:
   ```nix
   fading = false;
   ```

3. Change backend from "glx" to "xrender":
   ```nix
   backend = "xrender";
   ```

## Integration with BSPWM

Picom is automatically:
- **Started** by systemd user service on X11 session start
- **Managed** by home-manager configuration
- **Integrated** with bspwm window manager

The old manual startup method (in polybar.nix) has been removed in favor of systemd service management.

## Quick Reference

| Task | Command |
|------|---------|
| Edit config | `$EDITOR home/gig/common/optional/picom.nix` |
| Apply changes | `just home-bare` |
| Restart picom | `systemctl --user restart picom.service` |
| Check status | `systemctl --user status picom.service` |
| View logs | `journalctl --user -u picom.service -f` |
| Kill picom | `pkill picom` |
| Identify window | `xprop \| grep WM_CLASS` (then click window) |

## Related Files

- **Picom config:** `home/gig/common/optional/picom.nix`
- **BSPWM config:** `home/gig/common/optional/bspwm.nix`
- **Polybar config:** `home/gig/common/optional/polybar.nix`
- **System packages:** `hosts/common/optional/bspwm.nix`

---

**Last Updated:** 2026-02-27  
**Configured By:** Chief Engineer Montgomery Scott
