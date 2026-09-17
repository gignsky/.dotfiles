# Display Configuration Q&A - Ganoslal Dual-NVIDIA Setup

**Date**: 2026-03-15  
**System**: ganoslal - Dual NVIDIA (GTX 970 + RTX 3060 Ti)  
**Current Generation**: 21

---

## Question 1: Can I safely remove amdgpu?

### Answer: YES, you should remove AMD GPU references

**Current hardware** (verified via `lspci`):
```
23:00.0 VGA compatible controller: NVIDIA Corporation GM204 [GeForce GTX 970]
2d:00.0 VGA compatible controller: NVIDIA Corporation GA104 [GeForce RTX 3060 Ti]
```

You have **two NVIDIA GPUs**, no AMD GPU.

### Changes needed:

#### 1. Remove from `hosts/ganoslal/default.nix` (line 69-72):
**Current**:
```nix
services.xserver.videoDrivers = [
  "nvidia"
  "amdgpu"  # REMOVE THIS LINE
];
```

**Should be**:
```nix
services.xserver.videoDrivers = [ "nvidia" ];
```

#### 2. Remove from `hosts/ganoslal/hardware-configuration.nix`:

**Line 26** - Remove:
```nix
kernelModules = [ "amdgpu" ];  # DELETE THIS
```

**Lines 33-37** - Remove:
```nix
kernelParams = [
  # needed for GCN1 (Southern Island) cards i.e. my shitty second AMD card
  "radeon.si_support=0"
  "amdgpu.si_support=1"
];  # DELETE ALL OF THIS
```

Change to:
```nix
kernelParams = [ ];  # Empty or remove the whole line
```

---

## Question 1a: Do I need to specify "nvidia" twice?

### Answer: NO, once is sufficient

**Explanation**:
- `services.xserver.videoDrivers = [ "nvidia" ];` tells X11 to load the NVIDIA driver
- The driver automatically detects **ALL NVIDIA GPUs** in the system
- Both your GTX 970 and RTX 3060 Ti will be managed by the single `nvidia` driver
- The driver creates outputs for both cards (e.g., `HDMI-0`, `DP-1` from one card, `DVI-I-1-0` from another)

**What the driver does**:
1. Loads `nvidia.ko` kernel module
2. Scans PCI bus for NVIDIA devices
3. Initializes both GPUs (Bus IDs: `23:00.0` and `2d:00.0`)
4. Creates X11 outputs for all connected monitors across both cards

---

## Question 1b: How to interrogate X server at bootup (non-graphical)?

### Answer: Use logs and system commands

#### **Method 1: X11 Log File** (Most detailed)
```bash
# View X server initialization log
cat /var/log/Xorg.0.log

# Search for GPU detection
cat /var/log/Xorg.0.log | grep -i "nvidia\|gpu"

# Search for connected monitors
cat /var/log/Xorg.0.log | grep -i "connected\|output"

# Look for errors/warnings
cat /var/log/Xorg.0.log | grep -E "(EE)|(WW)"
```

This log is written **during X server startup**, before the graphical environment loads.

#### **Method 2: Systemd Journal**
```bash
# Display manager logs (includes X startup)
journalctl -b -u display-manager.service

# Kernel messages about GPU driver loading
journalctl -b -k | grep -i nvidia

# Full boot log filtered for display-related messages
journalctl -b | grep -E "xorg|nvidia|display|drm"
```

#### **Method 3: Kernel Driver Information**
```bash
# Check loaded NVIDIA driver (works from console/SSH)
cat /proc/driver/nvidia/version

# List loaded kernel modules
lsmod | grep nvidia

# Kernel ring buffer for GPU initialization
dmesg | grep -i nvidia
dmesg | grep -i drm
```

#### **Method 4: NVIDIA-specific tools** (requires X)
```bash
# These need X running but work from SSH if DISPLAY is set
nvidia-smi -L  # List GPUs
nvidia-smi -q  # Detailed GPU info
```

#### **Method 5: From TTY (Ctrl+Alt+F2)**
If you boot to a graphical environment but want to debug from console:
1. Press `Ctrl+Alt+F2` to switch to TTY2
2. Login
3. Run: `cat /var/log/Xorg.0.log | less`
4. Press `Ctrl+Alt+F1` to return to graphical session

---

## Question 2: Does xrandr step come before or after ly?

### Answer: Complex - it happens in stages

**Boot sequence**:
```
1. Kernel loads
   └─> NVIDIA kernel modules load (nvidia.ko, nvidia-drm.ko)
   └─> GPUs are initialized at kernel level

2. X11 server starts (via display-manager.service)
   └─> X loads NVIDIA driver
   └─> Driver enumerates connected displays
   └─> Creates outputs (HDMI-0, DP-1, etc.)
   └─> **Initial xrandr data is now available** ← BEFORE ly

3. ly display manager shows login screen
   └─> ly uses whatever display configuration X11 detected
   └─> May show on one monitor or mirrored depending on default config

4. User logs in

5. X session initialization runs
   └─> xsession.initExtra scripts execute
   └─> BSPWM starts
   └─> ganoslal.conf runs
   └─> **xrandr commands can now reconfigure displays** ← AFTER ly
```

**Key insight**: 
- xrandr **data is available** before ly (X11 creates it)
- xrandr **configuration commands** typically run after ly (during session init)
- **Problem**: Default X11 config may not enable all monitors automatically

---

## Question 2a.1: How to prevent timing issues?

### Answer: Multiple approaches

#### **Option A: Add explicit monitor initialization to X11 startup**

Add to `hosts/ganoslal/default.nix`:
```nix
services.xserver.displayManager.setupCommands = ''
  # This runs BEFORE display manager (ly) shows
  ${pkgs.xorg.xrandr}/bin/xrandr --output HDMI-0 --auto
  ${pkgs.xorg.xrandr}/bin/xrandr --output DP-1 --auto
  ${pkgs.xorg.xrandr}/bin/xrandr --output DP-2 --auto
  ${pkgs.xorg.xrandr}/bin/xrandr --output DP-3 --auto
  # Add all your monitors
  
  # Then configure layout
  ${pkgs.xorg.xrandr}/bin/xrandr \
    --output HDMI-0 --primary --mode 1920x1080 --pos 1920x1600 \
    --output DP-1 --mode 1920x1080 --pos 0x1600 \
    --output DP-2 --mode 1920x1080 --pos 3840x1600
'';
```

This runs **after X11 starts but before ly shows**, ensuring monitors are configured at login screen.

#### **Option B: Use systemd service with retries**

Use the template I created: `home/gig/common/optional/monitor-auto-recovery.nix`

Import it in your home-manager config:
```nix
imports = [
  ./monitor-auto-recovery.nix
  # ... other imports
];
```

This service:
- Runs after login
- Checks for expected monitor count
- Retries configuration every 30 seconds for up to 10 attempts
- Shows notification if all monitors are found or if it fails

#### **Option C: Add delay to BSPWM config**

Update `home/gig/common/resources/bspwm/ganoslal.conf`:
```bash
#!/bin/bash
echo "Loading ganoslal configuration..."

# Force xrandr to re-scan and enable all outputs
xrandr --output HDMI-0 --auto
xrandr --output DP-1 --auto
xrandr --output DP-2 --auto
xrandr --output DP-3 --auto
# ... repeat for all monitors

# Wait for monitors to stabilize
sleep 2

# Now detect monitors
AVAILABLE_MONITORS=$(xrandr --listmonitors 2>/dev/null | grep -v "Monitors:" | awk '{print $4}' || true)

# Rest of config...
```

---

## Question 2a.2: How to investigate monitors per GPU?

### Answer: Several diagnostic methods

#### **Method 1: xrandr with output naming**

Output names indicate which GPU they're from:
```bash
xrandr --query

# NVIDIA naming patterns:
# - HDMI-0, HDMI-1 = NVIDIA outputs
# - DP-0, DP-1, DP-2 = NVIDIA DisplayPort
# - DVI-I-0, DVI-D-0 = NVIDIA DVI
# 
# When you have multiple NVIDIA cards:
# - First card: HDMI-0, DP-0, DP-1
# - Second card: DVI-I-1-0, DVI-I-1-1 (note the extra -1-)
#   (The middle number indicates card index)
```

**Your current output** shows:
- `HDMI-0` = RTX 3060 Ti
- `DVI-I-1-0`, `DVI-I-1-1` = GTX 970 (note the `-1-` indicating second card)

#### **Method 2: nvidia-smi with output mapping**
```bash
# List GPUs
nvidia-smi -L

# Shows:
# GPU 0: NVIDIA GeForce GTX 970
# GPU 1: NVIDIA GeForce RTX 3060 Ti

# Use nvidia-settings to see which outputs belong to which GPU
nvidia-settings -q gpus

# Or use this to see all displays
nvidia-settings -q dpys
```

#### **Method 3: Check kernel DRM devices**
```bash
# List all DRM cards
ls -l /sys/class/drm/

# Show which card has which connectors
for card in /sys/class/drm/card*/card*-*/status; do
    echo "$card: $(cat $card)"
done

# Example output:
# /sys/class/drm/card0/card0-HDMI-A-1/status: connected
# /sys/class/drm/card1/card1-DP-1/status: connected
```

#### **Method 4: Use NVIDIA X Server Settings GUI**

```bash
# Launch NVIDIA settings
nvidia-settings

# Navigate to:
# - "X Server Display Configuration"
# - Shows visual layout of all monitors
# - Indicates which GPU each monitor is connected to
# - Allows configuration and testing
```

**Current issue you mentioned**:
> "nvidia x server settings only shows two displays as on"

This suggests X11 isn't enabling all monitors. Use `xrandr --auto` on each output to force them on.

---

## Question 2b: How to specify explicit monitor configuration?

### Answer: Multiple methods

#### **Method 1: Via NixOS X11 Configuration** (runs before ly)

Add to `hosts/ganoslal/default.nix`:
```nix
services.xserver.displayManager.setupCommands = ''
  # Comprehensive monitor configuration
  ${pkgs.xorg.xrandr}/bin/xrandr \
    --output HDMI-0 --mode 1920x1080 --pos 1920x1600 --primary --rotate normal \
    --output DP-1 --mode 1920x1080 --pos 0x1600 --rotate normal \
    --output DP-2 --mode 1920x1080 --pos 3840x1600 --rotate normal \
    --output DP-3 --mode 1920x1080 --pos 1920x0 --rotate normal \
    --output DVI-I-1-0 --mode 1920x1080 --pos 0x0 --rotate normal
'';
```

**Pros**: 
- Runs early (before ly)
- Declarative (in version control)

**Cons**: 
- Requires rebuild to change
- May need to list all possible outputs

#### **Method 2: Via BSPWM X Session Init** (runs after login)

Add to `home/gig/common/optional/bspwm.nix` in `xsession.initExtra`:
```nix
xsession.initExtra = ''
  # Configure monitors before anything else
  xrandr \
    --output HDMI-0 --mode 1920x1080 --pos 1920x1600 --primary \
    --output DP-1 --mode 1920x1080 --pos 0x1600 \
    --output DP-2 --mode 1920x1080 --pos 3840x1600 &
  
  # Wait for xrandr to finish
  sleep 2
  
  # Rest of initialization...
'';
```

#### **Method 3: Via autorandr** (recommended for complex setups)

See `docs/guides/autorandr-guide.md` for full details.

Quick version:
```bash
# Configure monitors with xrandr
xrandr --output HDMI-0 --mode 1920x1080 --pos 1920x1600 --primary # ... etc

# Save configuration
autorandr --save ganoslal-full

# Test loading
autorandr --load ganoslal-full

# Enable in NixOS config
programs.autorandr.enable = true;
```

#### **Method 4: Direct in ganoslal.conf**

Update `home/gig/common/resources/bspwm/ganoslal.conf` to include xrandr commands at the top:

```bash
#!/bin/bash
echo "Loading ganoslal 6-monitor configuration..."

# Configure physical monitor layout FIRST
xrandr \
  --output HDMI-0 --mode 1920x1080 --pos 1920x1600 --primary --rotate normal \
  --output DP-1 --mode 1920x1080 --pos 0x1600 --rotate normal \
  --output DP-2 --mode 1920x1080 --pos 3840x1600 --rotate normal \
  --output DP-3 --mode 1920x1080 --pos 1920x0 --rotate normal \
  --output DVI-I-1-0 --off \  # Disable if not using this output
  --output DVI-I-1-1 --off

sleep 1  # Let monitors stabilize

# Then BSPWM configuration
AVAILABLE_MONITORS=$(xrandr --listmonitors | grep -v "Monitors:" | awk '{print $4}')
# ... rest of bspc monitor assignments
```

---

## Question 2c: Verify PRIME sync is not affecting display

### Answer: CORRECT - you've disabled it

From your current `nvidia.nix` (line 26):
```nix
prime = {
  sync.enable = false;  # ← This is DISABLED
  nvidiaBusId = "PCI:2d:0:0";
};
```

**PRIME sync is NOT affecting your setup** because:
1. `sync.enable = false` means PRIME is inactive
2. PRIME is for **laptop hybrid graphics** (Intel + NVIDIA switching)
3. You have **dual NVIDIA desktop GPUs** - PRIME is irrelevant

**However**, I notice an issue:
- You have `prime.nvidiaBusId` set, but no `prime.amdgpuBusId` or `intelBusId`
- Since PRIME is disabled, these fields are ignored anyway
- **Recommendation**: Clean up the nvidia.nix file to remove PRIME entirely

### Cleaned up nvidia.nix should look like:

```nix
{ config, lib, ... }:
{
  nixpkgs.config.allowUnfree = lib.mkForce true;

  hardware = {
    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      modesetting.enable = true;
      open = false;
      nvidiaSettings = true;
      
      # Power management
      powerManagement.enable = lib.mkDefault true;
    };

    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
}
```

**Remove the entire `prime` section** - it's not needed for dual NVIDIA GPUs.

---

## Question 3: How to make BSPWM print verbose output?

### Answer: BSPWM logs to stderr, captured by X session

#### **Where BSPWM output goes**:
1. When started by X session: `~/.xsession-errors`
2. When using systemd (modern setup): `journalctl --user`
3. Echo statements in `ganoslal.conf` → same destinations

#### **Method 1: View X session errors log**
```bash
# Watch in real-time
tail -f ~/.xsession-errors

# View after login
cat ~/.xsession-errors | grep bspwm
```

#### **Method 2: View systemd user journal**
```bash
# All user session logs
journalctl --user -b

# Filter for BSPWM
journalctl --user -b | grep bspwm

# Follow in real-time
journalctl --user -f
```

#### **Method 3: Redirect BSPWM output explicitly**

Update `home/gig/common/optional/bspwm.nix`:
```nix
xsession.windowManager.bspwm = {
  enable = true;
  
  extraConfig = ''
    # Explicit logging
    BSPWM_LOG="$HOME/.local/share/bspwm.log"
    mkdir -p "$(dirname "$BSPWM_LOG")"
    
    exec 2>&1 | tee -a "$BSPWM_LOG"  # Log everything
    
    echo "=== BSPWM startup: $(date) ===" 
    
    # Load host-specific monitor configuration
    HOSTNAME=$(hostname)
    echo "Hostname: $HOSTNAME"
    # ... rest of config
  '';
};
```

Then view logs:
```bash
tail -f ~/.local/share/bspwm.log
```

#### **Method 4: Make ganoslal.conf more verbose**

Update `home/gig/common/resources/bspwm/ganoslal.conf`:
```bash
#!/bin/bash

# Set up logging
BSPWM_CONF_LOG="$HOME/.local/share/bspwm-ganoslal.log"
exec 1> >(tee -a "$BSPWM_CONF_LOG")
exec 2>&1

echo "========================================"
echo "BSPWM Ganoslal Config - $(date)"
echo "========================================"

# Enable bash debugging
set -x  # Print each command before executing

echo "Loading ganoslal 6-monitor configuration..."

# Detect available monitors
AVAILABLE_MONITORS=$(xrandr --listmonitors 2>/dev/null | grep -v "Monitors:" | awk '{print $4}' || true)
echo "Available monitors detected:"
echo "$AVAILABLE_MONITORS"

# Rest of config with verbose output...
```

Then check logs:
```bash
cat ~/.local/share/bspwm-ganoslal.log
```

---

## Question 3a: Systemd service for monitor retry

### Answer: YES - I've created a template

**File created**: `home/gig/common/optional/monitor-auto-recovery.nix`

**To use it**:

1. Import in `home/gig/ganoslal/default.nix` (or common home config):
```nix
imports = [
  ./common/optional/bspwm.nix
  ./common/optional/monitor-auto-recovery.nix  # ADD THIS
  # ... other imports
];
```

2. Customize the service for your setup:

Edit `monitor-auto-recovery.nix` and update:
```nix
# Line ~18
EXPECTED_MONITORS=6  # Your 6 monitors

# Lines ~40-47 - Add your actual monitor outputs
xrandr --output HDMI-0 --auto 2>/dev/null || true
xrandr --output DP-1 --auto 2>/dev/null || true
xrandr --output DP-2 --auto 2>/dev/null || true
# ... add all 6

# Lines ~50-53 - Your specific layout
xrandr --output HDMI-0 --primary --mode 1920x1080 --pos 1920x1600 \
       --output DP-1 --mode 1920x1080 --pos 0x1600 \
       # ... complete layout
```

3. Rebuild home-manager:
```bash
home-manager switch --flake .#gig@ganoslal
```

**What it does**:
- Runs 2 minutes after login
- Checks if all 6 monitors are detected
- If not, retries every 30 seconds for up to 10 attempts (5 minutes total)
- Shows notification if successful or if it fails
- Logs everything to `~/.local/share/monitor-recovery.log`

**Check service status**:
```bash
# Status
systemctl --user status monitor-auto-recovery.service

# View logs
journalctl --user -u monitor-auto-recovery.service

# View recovery log
cat ~/.local/share/monitor-recovery.log
```

---

## Question 4: Should I remove amdgpu support?

### Answer: YES - addressed in Question 1

See detailed answer above. Summary of changes needed:

1. `hosts/ganoslal/default.nix`: Remove `"amdgpu"` from `videoDrivers`
2. `hosts/ganoslal/hardware-configuration.nix`: Remove:
   - `kernelModules = [ "amdgpu" ];`
   - AMD-specific `kernelParams`

---

## Recommended Action Plan

### Immediate fixes (simple):

1. **Clean up GPU configuration**:
   ```nix
   # hosts/ganoslal/default.nix
   services.xserver.videoDrivers = [ "nvidia" ];  # Remove amdgpu
   
   # hosts/ganoslal/hardware-configuration.nix
   # Remove amdgpu kernelModules and kernelParams
   ```

2. **Add explicit monitor configuration** (easiest method):
   ```nix
   # hosts/ganoslal/default.nix
   services.xserver.displayManager.setupCommands = ''
     ${pkgs.xorg.xrandr}/bin/xrandr --output HDMI-0 --auto
     ${pkgs.xorg.xrandr}/bin/xrandr --output DP-1 --auto
     ${pkgs.xorg.xrandr}/bin/xrandr --output DP-2 --auto
     ${pkgs.xorg.xrandr}/bin/xrandr --output DP-3 --auto
     # Add complete layout here
   '';
   ```

3. **Update ganoslal.conf** to have better logging and delays:
   ```bash
   # Add at top of ganoslal.conf
   sleep 2  # Give monitors time to initialize
   xrandr --auto  # Force re-detection
   ```

### Advanced solutions (if issues persist):

4. **Try autorandr** for better monitor management
5. **Use monitor-auto-recovery.nix** systemd service for automatic retries

---

**Next Steps**:
1. Review the changes suggested above
2. Let me know which approach you'd like to implement
3. I can help make the specific edits to your configuration files

---

**Documentation Created**:
- ✅ `docs/guides/multi-gpu-display-debugging-cheatsheet.md`
- ✅ `docs/guides/autorandr-guide.md`
- ✅ `home/gig/common/optional/monitor-auto-recovery.nix` (template)

**Last Updated**: 2026-03-15 by Library Computer
