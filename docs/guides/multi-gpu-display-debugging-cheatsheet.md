# Multi-GPU Display Debugging Cheatsheet

**System**: Ganoslal (dual NVIDIA: GTX 970 + RTX 3060 Ti)  
**Date Created**: 2026-03-15  
**Environment**: NixOS with BSPWM + ly display manager

---

## GPU Hardware Information

### List all GPU devices
```bash
# Using lspci (needs pciutils package)
lspci | grep -E "VGA|3D|Display"

# With NixOS (if not installed system-wide)
nix-shell -p pciutils --run "lspci | grep -E 'VGA|3D|Display'"

# Expected output for ganoslal:
# 23:00.0 VGA compatible controller: NVIDIA Corporation GM204 [GeForce GTX 970]
# 2d:00.0 VGA compatible controller: NVIDIA Corporation GA104 [GeForce RTX 3060 Ti]
```

### Get detailed PCI bus information
```bash
# Full bus ID format needed for nvidia.nix
lspci -nn | grep -E "VGA|3D"

# Get just the bus IDs
lspci | grep -E "VGA|3D" | awk '{print $1}'
```

### NVIDIA-specific GPU listing
```bash
# List all NVIDIA GPUs with UUIDs
nvidia-smi -L

# Full GPU details
nvidia-smi

# Monitor GPU usage in real-time
nvidia-smi dmon -s pucvmet
```

---

## X11 Server Diagnostics

### Check X11 server logs (bootup information)
```bash
# Current X session log
cat /var/log/Xorg.0.log

# Search for connected monitors
cat /var/log/Xorg.0.log | grep -i "connected"

# Search for GPU initialization
cat /var/log/Xorg.0.log | grep -i "nvidia\|NVIDIA"

# Search for errors
cat /var/log/Xorg.0.log | grep -E "EE|WW"

# View with journalctl (includes systemd context)
journalctl -b -u display-manager.service

# All X-related logs since last boot
journalctl -b | grep -i xorg
```

### Check which display manager is running
```bash
# Check status
systemctl status display-manager.service

# See what's configured
cat /etc/systemd/system/display-manager.service
```

### Verify X11 is using correct drivers
```bash
# Check loaded kernel modules
lsmod | grep -E "nvidia|nouveau|amdgpu"

# Verify NVIDIA driver version
cat /proc/driver/nvidia/version

# Check X11 driver information
grep "LoadModule" /var/log/Xorg.0.log
```

---

## Monitor Detection & Configuration

### xrandr: Query display outputs

```bash
# Show all outputs and capabilities (detailed)
xrandr --query

# Short form - just list connected monitors
xrandr --listmonitors

# Get output names only
xrandr --query | grep " connected" | awk '{print $1}'

# Show disconnected outputs too
xrandr --query | grep -E "connected|disconnected"

# Query specific output
xrandr --query | grep -A 10 "HDMI-0"
```

### xrandr: Configure displays

```bash
# Enable a disconnected display
xrandr --output DP-1 --auto

# Set resolution manually
xrandr --output HDMI-0 --mode 1920x1080

# Position monitors relative to each other
xrandr --output DP-1 --left-of HDMI-0
xrandr --output DP-2 --right-of HDMI-0
xrandr --output DP-3 --above HDMI-0

# Absolute positioning (pixels from top-left)
xrandr --output HDMI-0 --pos 1920x0
xrandr --output DP-1 --pos 0x0

# Set primary monitor
xrandr --output HDMI-0 --primary

# Disable a monitor
xrandr --output DP-1 --off

# Complete layout example (3 monitors)
xrandr --output HDMI-0 --primary --mode 1920x1080 --pos 1920x0 --rotate normal \
       --output DP-1 --mode 1920x1080 --pos 0x0 --rotate normal \
       --output DP-2 --mode 1920x1080 --pos 3840x0 --rotate normal
```

### Monitor EDID information

```bash
# Get monitor EDID data (for autorandr fingerprints)
xrandr --props | grep EDID -A 8

# Using nvidia-settings (NVIDIA GPUs only)
nvidia-settings --query dpys

# Decode EDID with edid-decode (if installed)
nix-shell -p edid-decode --run "xrandr --props | edid-decode"
```

---

## BSPWM Monitor Management

### Query BSPWM monitor state

```bash
# List all monitors BSPWM knows about
bspc query -M --names

# List monitors with their IDs
bspc query -M

# Show desktop assignments per monitor
bspc query -D --names

# Show which monitor has which desktop
for monitor in $(bspc query -M --names); do
    echo "Monitor: $monitor"
    bspc query -D -m $monitor --names
done
```

### Configure BSPWM monitors manually

```bash
# Assign desktops to a monitor
bspc monitor HDMI-0 -d 1 2 3 4

# Reassign desktops
bspc monitor DP-1 -d 5 6 7 8

# Remove all desktops from a monitor
bspc monitor DP-1 -r

# Focus a specific monitor
bspc monitor -f HDMI-0
```

### BSPWM debugging

```bash
# Show all BSPWM state
bspc query -T

# Show specific monitor state
bspc query -T -m HDMI-0

# Show desktop state
bspc query -T -d ^1

# Check BSPWM configuration file location
echo $HOME/.config/bspwm/bspwmrc

# Restart BSPWM (reloads config)
bspc wm -r

# Check what config was loaded
ps aux | grep bspwm
```

---

## System Logs & Debugging

### Monitor system logs for display issues

```bash
# All logs since last boot
journalctl -b

# Display manager specific
journalctl -b -u display-manager.service

# Follow logs in real-time
journalctl -f

# Kernel messages (GPU driver loading)
dmesg | grep -i nvidia
dmesg | grep -i drm

# Search for specific time range
journalctl --since "10 minutes ago"
journalctl --since "2026-03-15 13:00:00"
```

### Check for errors during login

```bash
# User session logs
journalctl --user -b

# X session errors (user-level)
cat ~/.xsession-errors

# Check BSPWM startup logs
cat ~/.local/share/xorg/Xorg.0.log 2>/dev/null
```

---

## NixOS-Specific Commands

### Check current configuration

```bash
# Show active NixOS configuration
nixos-rebuild list-generations

# Show what's in current generation
nix-store -q --references /run/current-system

# Check which X11 packages are installed
nix-store -q --references /run/current-system | grep xorg
```

### Test configuration changes

```bash
# Build without activating
nixos-rebuild build

# Test temporarily (reverts on reboot)
sudo nixos-rebuild test

# Apply permanently
sudo nixos-rebuild switch
```

### Check derivation for X server

```bash
# Show X server config derivation
nix-store -q --tree /run/current-system/sw/bin/X

# Check xorg.conf location (NixOS auto-generates)
find /nix/store -name "xorg.conf" -type f 2>/dev/null | head -5
```

---

## NVIDIA-Specific Diagnostics

### Check NVIDIA driver status

```bash
# Driver version
nvidia-smi --query-gpu=driver_version --format=csv,noheader

# List all GPUs and their outputs
nvidia-settings -q screens
nvidia-settings -q dpys

# Check which GPU is handling X screen
nvidia-smi --query-gpu=index,name,display_active --format=csv

# Monitor GPU activity
watch -n 1 nvidia-smi
```

### NVIDIA X configuration

```bash
# Generate xorg.conf with nvidia-xconfig (for reference only, don't use on NixOS)
nvidia-xconfig --query-gpu-info

# Show current NVIDIA X configuration
nvidia-settings --query all | grep -i output
```

### PRIME debugging (when applicable)

```bash
# Check which GPU is rendering
glxinfo | grep "OpenGL renderer"

# Verify PRIME offload (if using offload mode)
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia glxinfo | grep "OpenGL renderer"

# List all GPU providers
xrandr --listproviders
```

---

## Environment Variables for Debugging

```bash
# Enable verbose X11 logging
export XORG_LOG_VERBOSITY=9

# NVIDIA debugging
export __GL_SYNC_TO_VBLANK=1
export __GL_SYNC_DISPLAY_DEVICE=HDMI-0

# Force specific GPU for rendering
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
```

---

## Quick Diagnostic Script

Save as `~/bin/display-diag.sh`:

```bash
#!/usr/bin/env bash
echo "=== GPU Hardware ==="
nix-shell -p pciutils --run "lspci | grep -E 'VGA|3D'"
echo ""

echo "=== NVIDIA GPUs ==="
nvidia-smi -L
echo ""

echo "=== X11 Outputs (xrandr) ==="
xrandr --listmonitors
echo ""

echo "=== Connected Displays ==="
xrandr --query | grep " connected"
echo ""

echo "=== BSPWM Monitors ==="
bspc query -M --names
echo ""

echo "=== BSPWM Desktops ==="
bspc query -D --names
echo ""

echo "=== Display Manager Status ==="
systemctl status display-manager.service --no-pager -l
echo ""

echo "=== Recent X11 Errors ==="
grep -E "EE|WW" /var/log/Xorg.0.log | tail -10
```

Make executable:
```bash
chmod +x ~/bin/display-diag.sh
```

---

## Useful One-Liners

```bash
# Show all connected monitors with resolutions
xrandr | grep -E "connected|Screen"

# Count connected monitors
xrandr | grep " connected" | wc -l

# List all BSPWM desktops with their monitors
bspc query -D -m HDMI-0 --names

# Check if a specific monitor is connected
xrandr | grep -q "DP-1 connected" && echo "DP-1 is connected" || echo "DP-1 not found"

# Show monitor configuration at a glance
xrandr --listmonitors && echo "---" && bspc query -M --names

# Reload BSPWM config
pkill -USR1 bspwm

# Force X server to re-detect monitors (sometimes works)
xrandr --auto
```

---

## Files to Check When Troubleshooting

```bash
# NixOS configuration
~/.dotfiles/hosts/ganoslal/default.nix
~/.dotfiles/hosts/ganoslal/nvidia.nix
~/.dotfiles/hosts/ganoslal/hardware-configuration.nix

# BSPWM configuration
~/.dotfiles/home/gig/common/optional/bspwm.nix
~/.dotfiles/home/gig/common/resources/bspwm/ganoslal.conf

# System logs
/var/log/Xorg.0.log
~/.xsession-errors
journalctl -b -u display-manager.service

# Active X configuration (auto-generated by NixOS)
/etc/X11/xorg.conf.d/
```

---

**Last Updated**: 2026-03-15 by Library Computer  
**Related Documentation**: See `autorandr-guide.md` for automated monitor management
