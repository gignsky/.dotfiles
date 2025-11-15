# bspwm Configuration Guide

## What is bspwm?

bspwm (Binary Space Partitioning Window Manager) is a tiling window manager that represents windows as leaves of a full binary tree. It is highly configurable, keyboard-driven, and lightweight, making it an excellent choice for users who prefer minimal resource usage and efficient workspace management.

### Key Features

- **Tiling Layout**: Automatically arranges windows in non-overlapping tiles
- **Keyboard-Driven**: Designed for keyboard-centric workflow
- **Minimal Resource Usage**: Lightweight and fast
- **Highly Configurable**: Separate configuration from hotkey management
- **EWMH Compliant**: Works well with modern desktop tools

## Enabling bspwm for ganoslal

To enable the bspwm window manager on your ganoslal host, you need to import the bspwm module in your host configuration.

### Step 1: Edit the ganoslal configuration

Open the ganoslal host configuration file:

```bash
vim hosts/ganoslal/default.nix
```

### Step 2: Add the bspwm module import

Add the following line to the `imports` section:

```nix
(configLib.relativeToRoot "hosts/common/optional/bspwm.nix")
```

Your imports section should look similar to this:

```nix
imports = [
  ./hardware-configuration.nix
  (configLib.relativeToRoot "hosts/common/core")
  
  # optional
  (configLib.relativeToRoot "hosts/common/optional/bspwm.nix")  # Add this line
  # (configLib.relativeToRoot "hosts/common/optional/xfce.nix")  # Comment out if you don't want XFCE
  # (configLib.relativeToRoot "hosts/common/optional/hyprland.nix")  # Comment out if you don't want Hyprland
  
  # ... rest of imports
];
```

**Note**: You may want to comment out or remove other desktop environment imports (like XFCE or Hyprland) to avoid conflicts, though having multiple window managers installed is possible.

### Step 3: Rebuild your system

After making the changes, rebuild your NixOS configuration:

```bash
cd ~/.dotfiles
just rebuild
```

Or use the standard NixOS rebuild command:

```bash
sudo nixos-rebuild switch --flake ~/.dotfiles#ganoslal
```

### Step 4: Reboot and select bspwm

After rebuilding, reboot your system:

```bash
reboot
```

At the login screen (ly), you should now be able to select "bspwm" as your session.

## What's Included

The bspwm module automatically installs and configures:

- **bspwm**: The window manager itself
- **sxhkd**: Simple X Hotkey Daemon for keyboard shortcuts
- **kitty**: Modern terminal emulator
- **rofi**: Application launcher
- **polybar**: Customizable status bar
- **picom**: Compositor for transparency and visual effects
- **feh**: Image viewer and wallpaper setter
- **dunst**: Notification daemon
- **pcmanfm**: Lightweight file manager
- **scrot**: Screenshot utility
- **htop**: System monitoring tool
- **networkmanagerapplet**: Network manager GUI applet

## Basic Usage

### Default Keybindings (sxhkd)

**Note**: The default keybindings depend on your sxhkd configuration. You'll need to create a `~/.config/sxhkd/sxhkdrc` file to define custom keybindings. Here are some common examples:

#### Window Management

- `Super + Enter`: Open terminal
- `Super + Space`: Open application launcher (rofi)
- `Super + q`: Close window
- `Super + m`: Toggle monocle mode (maximize)
- `Super + t`: Set window to tiled mode
- `Super + f`: Toggle fullscreen

#### Navigation

- `Super + {h,j,k,l}`: Focus window in direction (left, down, up, right)
- `Super + Shift + {h,j,k,l}`: Move window in direction
- `Super + {1-9}`: Switch to desktop 1-9
- `Super + Shift + {1-9}`: Move window to desktop 1-9

#### Layout

- `Super + Ctrl + {h,j,k,l}`: Resize window
- `Super + Alt + {h,j,k,l}`: Expand window in direction

### Configuration Files

bspwm uses separate configuration files:

1. **bspwm configuration**: `~/.config/bspwm/bspwmrc`
   - Window manager settings
   - Desktop configuration
   - Rules for specific applications

2. **sxhkd configuration**: `~/.config/sxhkd/sxhkdrc`
   - Keyboard shortcuts
   - Application bindings

## Customization with Home Manager

For a more declarative and reproducible configuration, you can use home-manager to manage your bspwm and sxhkd configurations.

### Example home-manager configuration

Create or edit your home-manager configuration (e.g., `home/gig/ganoslal.nix`):

```nix
{
  # bspwm configuration
  xsession.windowManager.bspwm = {
    enable = true;
    settings = {
      border_width = 2;
      window_gap = 12;
      split_ratio = 0.52;
      borderless_monocle = true;
      gapless_monocle = true;
    };
    monitors = {
      primary = [ "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" ];
    };
  };

  # sxhkd configuration
  services.sxhkd = {
    enable = true;
    keybindings = {
      # Terminal emulator
      "super + Return" = "kitty";
      
      # Application launcher
      "super + space" = "rofi -show drun";
      
      # Close window
      "super + q" = "bspc node -c";
      
      # Reload sxhkd
      "super + Escape" = "pkill -USR1 -x sxhkd";
      
      # Focus/move windows
      "super + {h,j,k,l}" = "bspc node -f {west,south,north,east}";
      "super + shift + {h,j,k,l}" = "bspc node -s {west,south,north,east}";
      
      # Switch desktops
      "super + {1-9,0}" = "bspc desktop -f '^{1-9,10}'";
      "super + shift + {1-9,0}" = "bspc node -d '^{1-9,10}'";
      
      # Toggle fullscreen/monocle
      "super + f" = "bspc desktop -l next";
      "super + m" = "bspc node -t ~fullscreen";
    };
  };
  
  # Polybar configuration
  services.polybar = {
    enable = true;
    # Add your polybar configuration here
  };
  
  # Picom compositor
  services.picom = {
    enable = true;
    fade = true;
    shadow = true;
    # Add more picom settings as needed
  };
}
```

Then rebuild your home-manager configuration:

```bash
home-manager switch --flake ~/.dotfiles#gig@ganoslal
```

## Tips and Best Practices

### 1. Start Simple

Begin with a minimal configuration and gradually add features as you learn the system.

### 2. Use Workspaces Effectively

bspwm supports multiple desktops (workspaces). Organize your workflow across different desktops:
- Desktop 1: Web browsing
- Desktop 2: Development
- Desktop 3: Communication
- etc.

### 3. Set a Wallpaper

Use `feh` to set a wallpaper:

```bash
feh --bg-scale /path/to/wallpaper.jpg
```

Add this to your `~/.config/bspwm/bspwmrc` to make it persistent.

### 4. Configure Polybar

Polybar is a highly customizable status bar. Check the [Polybar wiki](https://github.com/polybar/polybar/wiki) for configuration examples.

### 5. Learn the Keybindings

Keep a reference of your keybindings handy until you memorize them. You can create a cheat sheet or use tools like `rofi` to display available shortcuts.

### 6. Monitor Configuration

If you have multiple monitors, configure them in your bspwmrc:

```bash
bspc monitor HDMI-1 -d 1 2 3 4 5
bspc monitor eDP-1 -d 6 7 8 9 10
```

Use `xrandr` to identify your monitor names.

## Troubleshooting

### bspwm doesn't start

1. Check if X server is running: `echo $DISPLAY`
2. Look at logs: `journalctl -xe | grep bspwm`
3. Verify configuration files have correct syntax

### Keyboard shortcuts don't work

1. Ensure sxhkd is running: `pgrep sxhkd`
2. Check sxhkd configuration: `~/.config/sxhkd/sxhkdrc`
3. Test sxhkd: `sxhkd -c ~/.config/sxhkd/sxhkdrc`

### No status bar appears

1. Ensure polybar is running: `pgrep polybar`
2. Start polybar manually: `polybar &`
3. Add polybar to bspwmrc for autostart

## Additional Resources

- [bspwm GitHub Repository](https://github.com/baskerville/bspwm)
- [bspwm Manual](https://github.com/baskerville/bspwm/blob/master/doc/bspwm.1.asciidoc)
- [sxhkd Manual](https://github.com/baskerville/sxhkd)
- [r/bspwm Subreddit](https://www.reddit.com/r/bspwm/)
- [Arch Wiki - bspwm](https://wiki.archlinux.org/title/Bspwm)

## Example Configurations

For inspiration, you can explore these dotfiles repositories:
- Search GitHub for "bspwm dotfiles"
- Check r/unixporn for screenshot threads with bspwm setups

## Conclusion

bspwm is a powerful and flexible window manager that rewards the time invested in learning it. Start with the basics, customize gradually, and enjoy a fast, efficient desktop experience!

For questions or issues specific to this NixOS configuration, please open an issue in the repository.
