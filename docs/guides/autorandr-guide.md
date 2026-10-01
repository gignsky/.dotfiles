# Autorandr Guide: Automated Monitor Configuration

**Purpose**: Automatically detect and configure multi-monitor setups based on connected displays  
**System**: NixOS with multiple GPUs  
**Date**: 2026-03-15

---

## What is Autorandr?

**Autorandr** is a tool that:
1. **Detects** which monitors are currently connected
2. **Matches** the detected setup against saved profiles (using EDID fingerprints)
3. **Automatically applies** the correct xrandr configuration for that profile
4. **Handles hotplugging** - can reconfigure when monitors are connected/disconnected

Think of it as "saved presets" for your monitor layouts that apply automatically.

---

## How Autorandr Works

### 1. Monitor Fingerprinting
- Each monitor broadcasts an **EDID** (Extended Display Identification Data)
- Autorandr reads the EDID from each connected monitor
- Creates a unique fingerprint for each monitor
- Stores fingerprints in profiles

### 2. Profile Matching
- When monitors change (boot, hotplug), autorandr scans connected monitors
- Compares detected EDIDs against saved profiles
- If a match is found, applies the saved xrandr configuration
- If no match, can fall back to a default profile

### 3. Configuration Storage
- Each profile contains:
  - **Fingerprints**: EDID hashes for expected monitors
  - **xrandr config**: Resolution, position, rotation for each monitor
  - **Scripts**: Optional pre/post-switch commands

---

## NixOS Configuration

### Basic Setup

Add to your `hosts/ganoslal/default.nix`:

```nix
{
  # Enable autorandr
  programs.autorandr = {
    enable = true;
    
    # Optional: automatically switch profiles on monitor changes
    hooks = {
      postswitch = {
        "notify-user" = ''
          ${pkgs.libnotify}/bin/notify-send "Autorandr" "Switched to profile $AUTORANDR_CURRENT_PROFILE"
        '';
        # Restart BSPWM to reconfigure desktops
        "reload-bspwm" = ''
          ${pkgs.bspwm}/bin/bspc wm -r
        '';
      };
    };
  };
  
  # Ensure autorandr runs on login
  services.autorandr.enable = true;
}
```

### Advanced Configuration with Profiles

Create profiles directly in your NixOS configuration:

```nix
{
  programs.autorandr = {
    enable = true;
    
    profiles = {
      # Profile 1: All 6 monitors connected (ganoslal full setup)
      "ganoslal-6-monitor" = {
        fingerprint = {
          # Get fingerprints by running: autorandr --fingerprint
          HDMI-0 = "00ffffffffffff004c2d...";  # Replace with actual EDID
          DP-1 = "00ffffffffffff00220e...";
          DP-2 = "00ffffffffffff00220e...";
          # ... etc for all monitors
        };
        
        config = {
          HDMI-0 = {
            enable = true;
            primary = true;
            position = "1920x0";
            mode = "1920x1080";
            rate = "60.00";
            rotate = "normal";
          };
          
          DP-1 = {
            enable = true;
            position = "0x0";
            mode = "1920x1080";
            rate = "60.00";
          };
          
          DP-2 = {
            enable = true;
            position = "3840x0";
            mode = "1920x1080";
            rate = "60.00";
          };
          
          # Continue for all monitors...
        };
        
        hooks = {
          postswitch = ''
            # Reload bspwm with 6-monitor config
            source ~/.config/bspwm/resources/ganoslal.conf
          '';
        };
      };
      
      # Profile 2: Fallback single monitor
      "single-monitor" = {
        fingerprint = {
          HDMI-0 = "00ffffffffffff004c2d...";
        };
        
        config = {
          HDMI-0 = {
            enable = true;
            primary = true;
            mode = "1920x1080";
            position = "0x0";
          };
        };
      };
      
      # Profile 3: Common office setup (example)
      "home-desk" = {
        fingerprint = {
          HDMI-0 = "00ffffffffffff004c2d...";
          DP-1 = "00ffffffffffff00220e...";
        };
        
        config = {
          HDMI-0.enable = true;
          HDMI-0.primary = true;
          HDMI-0.position = "0x0";
          HDMI-0.mode = "1920x1080";
          
          DP-1.enable = true;
          DP-1.position = "1920x0";
          DP-1.mode = "1920x1080";
        };
      };
    };
  };
}
```

---

## Manual Autorandr Workflow

### Creating Profiles Manually

This is often easier than writing NixOS config manually:

```bash
# 1. Connect your monitors and configure them with xrandr
xrandr --output HDMI-0 --primary --mode 1920x1080 --pos 1920x0 \
       --output DP-1 --mode 1920x1080 --pos 0x0 \
       --output DP-2 --mode 1920x1080 --pos 3840x0

# 2. Verify the layout looks correct
xrandr --query

# 3. Save this configuration as a profile
autorandr --save ganoslal-6-monitor

# 4. Check the saved profile
autorandr --config

# 5. Test loading the profile
autorandr --load ganoslal-6-monitor

# 6. Set as default
autorandr --default ganoslal-6-monitor
```

### Profile Storage Locations

Manually created profiles are stored in:
```
~/.config/autorandr/
  ├── ganoslal-6-monitor/
  │   ├── config         # xrandr configuration
  │   ├── setup          # EDID fingerprints
  │   ├── postswitch     # Optional script
  │   └── preswitch      # Optional script
  └── other-profile/
      └── ...
```

---

## Autorandr Commands

### Basic Usage

```bash
# List all profiles
autorandr --list
autorandr

# Show current profile
autorandr --current

# Detect and auto-switch to matching profile
autorandr --change
autorandr -c

# Load specific profile
autorandr --load <profile-name>
autorandr -l <profile-name>

# Save current xrandr config as new profile
autorandr --save <profile-name>
autorandr -s <profile-name>

# Remove a profile
autorandr --remove <profile-name>

# Force load even if fingerprints don't match
autorandr --load <profile-name> --force
```

### Debugging & Information

```bash
# Show detected monitors with fingerprints
autorandr --fingerprint

# Dry-run (show what would happen)
autorandr --dry-run

# Verbose output
autorandr --debug

# Show configuration for a profile
autorandr --config <profile-name>

# Batch mode (for scripts)
autorandr --batch
```

---

## Integration with BSPWM

### Method 1: Autorandr Hooks

Create profile-specific hooks that reload BSPWM:

```bash
# In ~/.config/autorandr/ganoslal-6-monitor/postswitch
#!/bin/bash

# Reload BSPWM configuration
bspc wm -r

# Or source specific config
source ~/.config/bspwm/resources/ganoslal.conf

# Restart polybar if needed
pkill polybar
polybar &
```

Make executable:
```bash
chmod +x ~/.config/autorandr/ganoslal-6-monitor/postswitch
```

### Method 2: Systemd Service Integration

Create a service that runs autorandr on login and monitor changes:

```nix
# In your NixOS configuration
systemd.user.services.autorandr = {
  description = "Autorandr monitor configuration";
  wantedBy = [ "graphical-session.target" ];
  
  serviceConfig = {
    Type = "oneshot";
    ExecStart = "${pkgs.autorandr}/bin/autorandr --change";
    RemainAfterExit = true;
  };
};

# Watch for monitor hotplug events
systemd.user.paths.autorandr = {
  wantedBy = [ "graphical-session.target" ];
  
  pathConfig = {
    PathChanged = "/sys/class/drm";
  };
  
  triggersOn = [ "autorandr.service" ];
};
```

### Method 3: Update BSPWM Config

Modify `~/.dotfiles/home/gig/common/resources/bspwm/ganoslal.conf` to run autorandr first:

```bash
#!/bin/bash

echo "Loading ganoslal configuration..."

# Run autorandr to configure monitors first
autorandr --change || autorandr --load ganoslal-6-monitor --force

# Wait for monitors to stabilize
sleep 1

# Now configure BSPWM based on available monitors
AVAILABLE_MONITORS=$(xrandr --listmonitors 2>/dev/null | grep -v "Monitors:" | awk '{print $4}' || true)
echo "Available monitors: $AVAILABLE_MONITORS"

# Rest of BSPWM configuration...
```

---

## Workflow Comparison

### Without Autorandr (Current)
1. X11 starts → detects monitors (inconsistent)
2. ly display manager shows → may mirror or show on wrong monitor
3. Login → BSPWM starts
4. BSPWM runs ganoslal.conf → queries xrandr
5. **Problem**: xrandr may not have all monitors enabled yet

### With Autorandr
1. X11 starts → detects monitors
2. Autorandr runs → matches fingerprints → applies saved xrandr layout
3. **All monitors positioned correctly before login**
4. ly display manager shows on correct monitor
5. Login → BSPWM starts
6. BSPWM runs ganoslal.conf → all monitors already available and positioned
7. BSPWM assigns desktops to properly configured monitors

---

## Getting Fingerprints for Your Setup

To create a proper autorandr profile, you need EDID fingerprints:

```bash
# Method 1: Autorandr built-in
autorandr --fingerprint

# Example output:
# HDMI-0 00ffffffffffff004c2d8d0a484d4b30...
# DP-1 00ffffffffffff00220e8a3401010101...

# Method 2: Directly from xrandr
xrandr --props | grep -A 8 "EDID:"

# Method 3: Read from sysfs
for output in /sys/class/drm/card*/card*/edid; do
    echo "Output: $output"
    hexdump -C "$output"
done
```

---

## Troubleshooting

### Autorandr not detecting monitors

```bash
# Check what autorandr sees
autorandr --fingerprint

# Compare with xrandr
xrandr --query

# If mismatch, regenerate profile
autorandr --save <profile> --force
```

### Profile not auto-switching

```bash
# Check systemd service status
systemctl --user status autorandr.service

# Manually trigger
autorandr --change --debug

# Check udev rules (if using hotplug)
udevadm monitor --environment --udev | grep -i drm
```

### Wrong profile loading

```bash
# Check current profile
autorandr --current

# See all profiles and their fingerprints
for profile in ~/.config/autorandr/*; do
    echo "Profile: $(basename $profile)"
    cat "$profile/setup"
done

# Force correct profile
autorandr --load correct-profile --force
```

---

## Recommended Setup for Ganoslal

Given your dual-NVIDIA setup with inconsistent monitor detection:

### 1. Create Profile Manually First

```bash
# Boot with all monitors connected
# Configure ideal layout with nvidia-settings or xrandr

# Example full layout:
xrandr --output HDMI-0 --primary --mode 1920x1080 --pos 1920x1600 \
       --output DP-1 --mode 1920x1080 --pos 0x1600 \
       --output DP-2 --mode 1920x1080 --pos 3840x1600 \
       --output DP-3 --mode 1920x1080 --pos 1920x0 \
       # ... add all your monitors

# Save as autorandr profile
autorandr --save ganoslal-all-monitors
```

### 2. Add to NixOS Config

```nix
# hosts/ganoslal/default.nix
{
  programs.autorandr.enable = true;
  services.autorandr.enable = true;
  
  # Optional: set default profile
  programs.autorandr.profiles = {
    # Profile will be read from ~/.config/autorandr/ganoslal-all-monitors/
  };
}
```

### 3. Integrate with BSPWM

Update `home/gig/common/resources/bspwm/ganoslal.conf`:

```bash
#!/bin/bash
echo "Loading ganoslal configuration..."

# Apply autorandr profile FIRST
if command -v autorandr &> /dev/null; then
    echo "Running autorandr..."
    autorandr --change --default ganoslal-all-monitors
    sleep 2  # Give monitors time to initialize
fi

# Then configure BSPWM (existing code)
AVAILABLE_MONITORS=$(xrandr --listmonitors | grep -v "Monitors:" | awk '{print $4}')
# ... rest of config
```

---

## Alternative: Simple Shell Script Approach

If autorandr seems too complex, you can create a simple monitor initialization script:

**`~/.config/bspwm/scripts/init-monitors.sh`**:
```bash
#!/bin/bash

# Wait for all monitors to be detected
sleep 2

# Force enable all known outputs
xrandr --output HDMI-0 --auto \
       --output DP-1 --auto \
       --output DP-2 --auto \
       --output DP-3 --auto \
       # ... etc

# Apply layout
xrandr --output HDMI-0 --primary --mode 1920x1080 --pos 1920x1600 \
       --output DP-1 --mode 1920x1080 --pos 0x1600 \
       --output DP-2 --mode 1920x1080 --pos 3840x1600 \
       # ... complete layout

echo "Monitor initialization complete"
```

Call from `xsession.initExtra` in bspwm.nix:
```nix
xsession.initExtra = ''
  # Initialize monitors before anything else
  ~/.config/bspwm/scripts/init-monitors.sh &
  
  # Rest of init...
'';
```

---

## Recommendation

**For your specific case** (dual NVIDIA with timing issues):

1. **Start simple**: Use the shell script approach above
2. **If that works**: Graduate to autorandr for hotplug support
3. **If problems persist**: May need systemd service with retries (see next section)

**Autorandr is best when**:
- You frequently move between different monitor setups
- You use laptop docking stations
- You need hotplug detection

**Shell script is better when**:
- Fixed desktop setup (like ganoslal)
- Just need reliable startup configuration
- Want simpler debugging

---

**Last Updated**: 2026-03-15 by Library Computer  
**Related**: See `multi-gpu-display-debugging-cheatsheet.md` for diagnostic commands
