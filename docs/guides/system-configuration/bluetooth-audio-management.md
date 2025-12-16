# Bluetooth Audio Management Guide

Complete guide for managing Bluetooth connections and audio output switching for dual-monitor movie setups.

## Overview

This setup provides both TUI and GUI tools for managing Bluetooth devices and switching audio outputs seamlessly between laptop speakers, TV/monitor audio, and Bluetooth earbuds.

## Installed Tools

### Bluetooth Management
- **`bluetuith`** - Terminal UI for Bluetooth device pairing and connection
- **`blueman`** (optional) - GUI alternative for Bluetooth management

### Audio Management  
- **`pwvucontrol`** - Modern PipeWire volume control and device switching
- **`helvum`** - Visual PipeWire patchbay for advanced audio routing
- **`wpctl`** - Command-line PipeWire control (already available)

## Quick Movie Setup Workflow

### Step 1: Connect Bluetooth Earbuds
```bash
# Launch Bluetooth TUI
bluetuith

# In bluetuith:
# - Press 's' to scan for devices
# - Use arrow keys to select your earbuds
# - Press Enter to pair/connect
# - Press 'q' to quit when connected
```

### Step 2: Switch Audio Output
```bash
# GUI method - Launch audio control
pwvucontrol

# CLI method - List audio devices
wpctl status

# CLI method - Switch to Bluetooth (example device ID 65)
wpctl set-default 65
```

### Step 3: Start Your Movie
Your movie will now play on the external monitor/TV while audio goes to your Bluetooth earbuds!

## Detailed Tool Usage

### bluetuith (TUI Bluetooth Manager)

**Launch:** `bluetuith`

**Key Controls:**
- `s` - Scan for new devices
- `↑/↓` - Navigate device list  
- `Enter` - Pair/Connect selected device
- `d` - Disconnect device
- `r` - Remove/unpair device
- `q` - Quit
- `?` - Show help

**Tips:**
- Put your earbuds in pairing mode before scanning
- First connection requires pairing, subsequent connections are automatic
- Device will show "Connected" status when successfully paired

### pwvucontrol (Audio Device Manager)

**Launch:** `pwvucontrol`

**Features:**
- Visual volume controls for all audio devices
- Easy output device switching via dropdown
- Per-application volume control
- Real-time audio level monitoring
- PipeWire-native interface

**Usage:**
- **Output Tab:** Switch between speakers, HDMI, Bluetooth
- **Input Tab:** Manage microphone inputs
- **Applications Tab:** Control volume per application
- **Devices Tab:** View all available audio hardware

### helvum (Visual Audio Router)

**Launch:** `helvum`

**Use Cases:**
- Complex audio routing scenarios
- Sending different apps to different outputs
- Creating audio chains and effects
- Troubleshooting audio connections

### Command Line Audio Control

**List all audio devices:**
```bash
wpctl status
```

**Set default output device:**
```bash
wpctl set-default [DEVICE_ID]
```

**Control volume:**
```bash
wpctl set-volume [DEVICE_ID] 0.7    # 70% volume
wpctl set-volume @DEFAULT_SINK@ 0.5 # 50% volume for default output
```

**Mute/unmute:**
```bash
wpctl set-mute @DEFAULT_SINK@ toggle
```

## Troubleshooting

### Bluetooth Issues
- **Device won't pair:** Try `sudo systemctl restart bluetooth`
- **Audio stutters:** Check if device supports A2DP profile
- **Connection drops:** Move closer to laptop, check for interference

### Audio Issues  
- **No sound after switching:** Restart the media application
- **Wrong device selected:** Use `wpctl status` to verify default sink
- **Audio delay:** Some Bluetooth devices have inherent latency

### PipeWire Issues
- **Service not running:** `systemctl --user restart pipewire`
- **No devices shown:** `systemctl --user restart wireplumber`

## Advanced Tips

### Auto-connect Bluetooth on Boot
```bash
# Trust device permanently (run in bluetuith or use CLI)
bluetoothctl trust [MAC_ADDRESS]
```

### Create Audio Profiles
Use helvum to create complex routing setups and save configurations for different usage scenarios.

### Hotkeys Setup
Consider adding window manager hotkeys for:
- `bluetuith` - Quick Bluetooth management
- `pwvucontrol` - Audio device switching  
- `wpctl set-mute @DEFAULT_SINK@ toggle` - Quick mute/unmute

## System Integration

The tools are installed via home-manager in `home/gig/home.nix`:

```nix
# Bluetooth and Audio Management
bluetuith        # TUI Bluetooth manager
pwvucontrol      # Modern PipeWire volume control GUI  
helvum           # PipeWire patchbay for advanced audio routing
# blueman        # Alternative GUI Bluetooth manager (uncomment if preferred)
```

All tools integrate seamlessly with your existing PipeWire audio system and require no additional configuration.
