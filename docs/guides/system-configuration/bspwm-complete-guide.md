# BSPWM Complete Guide & Component Interaction

## Component Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         BSPWM ECOSYSTEM                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐    ┌──────────────┐    ┌─────────────────┐ │
│  │   X Server  │◄──►│    bspwm     │◄──►│  Applications   │ │
│  │  (Display)  │    │(Window Mgr)  │    │   (Firefox,     │ │
│  └─────────────┘    └──────────────┘    │    Wezterm)     │ │
│         │                    │          └─────────────────┘ │
│         ▼                    ▼                              │
│  ┌─────────────┐    ┌──────────────┐                       │
│  │   polybar   │    │    sxhkd     │                       │
│  │ (Status Bar)│    │(Hotkey Daemon│                       │
│  └─────────────┘    │& Keybindings)│                       │
│         │            └──────┬───────┘                       │
│         ▼                   │                               │
│  ┌─────────────┐            ▼                               │
│  │    rofi     │    ┌──────────────┐                       │
│  │(App Launcher│    │  External    │                       │
│  │ & Menus)    │    │   Programs   │                       │
│  └─────────────┘    │ (feh, maim,  │                       │
│                      │  pactl, etc) │                       │
│                      └──────────────┘                       │
└─────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

### **bspwm** - Core Window Manager
- **Purpose**: Manages window placement, tiling, workspaces
- **Config File**: `~/.config/bspwm/bspwmrc` 
- **Controls**: Window layouts, workspace behavior, window rules
- **Does NOT handle**: Keybindings (delegated to sxhkd)

### **sxhkd** - Hotkey Daemon  
- **Purpose**: Handles ALL keyboard shortcuts
- **Config File**: `~/.config/sxhkd/sxhkdrc`
- **Controls**: Key combinations → command execution
- **Manages**: Application launching, window manipulation, system controls

### **polybar** - Status Bar
- **Purpose**: System information display
- **Config File**: `~/.config/polybar/config.ini`
- **Displays**: Time, workspaces, system stats, network, audio

### **rofi** - Application Launcher & Menus
- **Purpose**: Interactive menus and application launching
- **Modes**: 
  - `drun` (Desktop Applications) 
  - `run` (Command Line Tools)
  - `window` (Window Switcher)
- **Used by**: sxhkd keybindings, help system

### **External Tools**
- **feh**: Wallpaper setting
- **maim**: Screenshots  
- **pactl**: Audio control
- **brightnessctl**: Brightness control

## Refresh & Reload Commands

### Force Keybinding Refresh
```bash
# Method 1: Restart bspwm (recommended - reloads everything)
super + alt + r
# OR manually: bspc wm -r

# Method 2: Restart sxhkd only
pkill sxhkd && sxhkd &

# Method 3: Send reload signal to sxhkd
pkill -USR1 sxhkd
```

### Check Current Configuration
```bash
# View active sxhkd config
cat ~/.config/sxhkd/sxhkdrc

# Test if sxhkd is running
pgrep sxhkd

# View bspwm rules and settings
bspc query -T
```

### Force Background Refresh
```bash
# Manual refresh
feh --bg-scale ~/.background-image

# Via new keybinding (after home-manager rebuild)
super + shift + w
```

## Troubleshooting Guide

### Keybindings Not Working
1. **Check sxhkd is running**: `pgrep sxhkd`
2. **Restart sxhkd**: `pkill sxhkd && sxhkd &`
3. **Check config syntax**: Look for syntax errors in sxhkdrc
4. **Test specific key**: Use `xev` to verify key codes

### Help Menu Not Working  
**Issue**: `super + shift + question` may have parsing problems

**Debug Steps**:
```bash
# Test the command manually
rofi -dmenu -p "bspwm help" -i -markup-rows -no-custom -auto-select <<< "test"

# Check if rofi is available
which rofi
```

**Fix**: The multiline string in sxhkd might need different quoting

### Configuration Not Updating
1. **Home Manager**: Run `just home` to rebuild user configs
2. **NixOS**: Run `just rebuild` for system-wide changes  
3. **Force reload**: Restart bspwm/sxhkd manually after rebuild

## Key Refresh Workflow

**After making changes to bspwm.nix:**

1. **Rebuild home-manager**:
   ```bash
   just home
   ```

2. **Restart bspwm** (automatically reloads sxhkd too):
   ```bash
   super + alt + r
   # OR manually: bspc wm -r
   ```

3. **Test keybindings**:
   ```bash
   super + question             # Should show help (note: just super + ?, no shift!)
   super + d                    # Should show run launcher
   super + u                    # Should restore minimized window
   ```

## Cheat Sheet

### Essential Keybindings
| Key Combination | Action |
|----------------|--------|
| `super + Return` | Terminal (wezterm) |
| `super + space` | Desktop apps (rofi drun) |
| `super + d` | Command launcher (rofi run) |
| `super + question` | Help menu |
| `super + m` | Minimize window |
| `super + u` | Restore last minimized |
| `super + shift + w` | Refresh wallpaper |

### Window Management
| Key | Action |
|-----|--------|
| `super + w` | Close window |
| `super + shift + q` | Kill window |
| `super + f` | Toggle floating |
| `super + shift + f` | Toggle fullscreen |
| `super + h/j/k/l` | Focus direction |

### System Controls  
| Key | Action |
|-----|--------|
| `super + alt + r` | Restart bspwm |
| `super + alt + Escape` | Quit bspwm |
| `Print` | Screenshot selection |
| `super + Print` | Screenshot full screen |

## Advanced Configuration

### Custom Keybinding Addition
```nix
# In bspwm.nix keybindings section
"super + ctrl + t" = "${pkgs.alacritty}/bin/alacritty";
```

### Window Rules
```nix
# In bspwm windowManagerCommand
echo "bspc rule -a Firefox desktop='^2'"
echo "bspc rule -a code-oss desktop='^3'"
```

This guide provides both high-level architecture understanding and practical troubleshooting steps for bspwm ecosystem management.
