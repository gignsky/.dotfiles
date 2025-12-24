# BSPWM Visual Enhancement Suite - System Enhancement Protocol

**Status**: Planning\
**Priority**: High\
**Estimated Scope**: 1-2 sessions\
**Lead Engineer**: Montgomery Scott\
**Created**: 2025-12-14\
**Last Updated**: 2025-12-14

## Objective

Transform the bspwm window manager setup on Merlin into a visually stunning and
functionally rich desktop environment. This enhancement focuses on implementing
a professional status bar, dynamic wallpapers with transparency effects, and
polish that makes the desktop both beautiful and productive.

**Goals:**

- Implement comprehensive status bar with system monitoring
- Add animated/rotating wallpapers with transparency effects
- Create a cohesive visual theme that enhances productivity
- Ensure all enhancements integrate seamlessly with existing bspwm configuration

## Current Plan

- ~~Initial bspwm configuration~~ ✓ (completed 2025-12-08)
- ~~SEP protocol implementation~~ ✓ (completed 2025-12-14)
- Status bar implementation (Polybar - primary choice)
- WezTerm terminal configuration optimization (Phase 0)
- Foundation configuration review and optimization (Phase 1)
- ~~Waybar exploration~~ (skipped - focused on Polybar for bspwm)
- Transparency and compositor effects enhancement
- Animated/rotating wallpaper system
- Visual theming and polish integration
- Testing and optimization phase

## Technical Requirements

- [ ] **WezTerm Terminal Configuration**:
  - Font optimization and ligature support
  - Color scheme and theme integration
  - Transparency and opacity settings
  - Keybinding customization
  - Performance optimization
  - Integration with bspwm workflow

- [ ] **Status Bar (Polybar)**:
  - System resource monitoring (CPU, RAM, disk)
  - Workspace indicators with bspwm integration
  - Audio controls and volume display
  - Network status and connectivity info
  - Date/time display with customizable format
  - Custom styling matching overall theme

- [ ] **Visual Effects System**:
  - Enhanced Picom configuration for transparency
  - Window blur effects for inactive windows
  - Fade animations and smooth transitions
  - Drop shadows and rounded corners

- [ ] **Wallpaper Management**:
  - Animated wallpaper support (mpvpaper or xwinwrap)
  - Rotating wallpaper slideshow (variety or custom script)
  - Dynamic color scheme generation (pywal integration)
  - Time-based or weather-responsive backgrounds

- [ ] **Theme Integration**:
  - Coordinated GTK themes
  - Custom icon pack selection
  - Enhanced font rendering optimization
  - Rofi styling to match overall aesthetic

## Implementation Checklist

### Phase 0: WezTerm Terminal Configuration

- [ ] Review current WezTerm configuration and settings
- [ ] Optimize font rendering and typography
- [ ] Configure color schemes and visual appearance
- [ ] Set up proper keybindings and shortcuts
- [ ] Configure window behavior and opacity
- [ ] Test performance and responsiveness
- [ ] Integrate with overall desktop theme
- [ ] Document final configuration choices

### Phase 1: Foundation Configuration Review

- [ ] Review current bspwm basic configuration settings
- [ ] Analyze Merlin-specific bspwm config file (`merlin.conf`)
- [ ] Explore and optimize core bspwm options:
  - [ ] Window management behavior (focus, tiling, gaps)
  - [ ] Desktop/workspace configuration and naming
  - [ ] Monitor detection and layout optimization
  - [ ] Border and visual feedback settings
- [ ] Test and validate current hotkey mappings (sxhkd)
- [ ] Identify any missing essential bspwm functionality
- [ ] Document current configuration baseline
- [ ] Optimize any suboptimal settings discovered

### Phase 2: Status Bar Foundation

- [x] Install and configure Polybar package in NixOS configuration
- [x] Create basic Polybar configuration file
- [x] Implement bspwm workspace integration
- [x] Add system resource monitoring modules
- [x] Configure audio and network status displays
- [ ] Test status bar functionality and positioning

### Phase 3: Visual Effects Enhancement

- [ ] Enhance existing Picom configuration
- [ ] Implement window transparency rules
- [ ] Add blur effects for inactive windows
- [ ] Configure fade animations and transitions
- [ ] Apply drop shadows and rounded corner effects
- [ ] Test performance impact of visual effects

### Phase 4: Wallpaper System

- [ ] Choose and implement animated wallpaper solution
- [ ] Set up wallpaper rotation system
- [ ] Integrate dynamic color scheme generation
- [ ] Configure wallpaper directory and management
- [ ] Test wallpaper system stability and performance

### Phase 5: Theme Integration & Polish

- [ ] Select and configure GTK theme
- [ ] Install and configure icon pack
- [ ] Optimize font rendering settings
- [ ] Style Rofi to match overall theme
- [ ] Create custom color schemes if needed
- [ ] Final testing and optimization

## Technical Notes

### 2025-12-14 - Initial Analysis

- **Current bspwm setup**: Functional with basic transparency via Picom
- **Monitor configuration**: Dynamic dual-monitor support already implemented
  for Merlin
- **Performance considerations**: Framework 16 laptop should handle visual
  effects well
- **Integration points**: Need to coordinate with existing sxhkd hotkeys and
  bspwm rules
- **Foundation review needed**: Captain identified need for Phase 1 to review
  and optimize basic bspwm configuration before visual enhancements
- **Terminal priority**: Captain identified WezTerm configuration as new Phase
  0 - essential foundation before window manager optimization

### WezTerm Configuration Planning

- **Current status**: WezTerm installed and functional but may need optimization
- **Priority areas**: Font rendering, color schemes, keybindings, transparency
  integration
- **Integration goal**: Seamless coordination with bspwm and overall desktop
  theme

### Status Bar Research

- **Polybar advantages**: Mature, excellent bspwm integration, highly
  customizable
- **Configuration approach**: NixOS declarative configuration vs traditional
  config files
- **Module priorities**: Workspaces, resources, audio, network, date/time

### Polybar Implementation (2025-12-23)

- **Configuration Method**: Implemented via home-manager `services.polybar`
- **Theme**: Nord-inspired color scheme (#2E3440 background, #D8DEE9 foreground)
- **Features Implemented**:
  - bspwm workspace integration with visual focus indicators
  - System monitoring: CPU, memory, filesystem usage
  - Audio: PulseAudio with volume bar visualization
  - Network: Both wireless and ethernet status
  - Battery: Charging/discharging animations for laptop use
  - Date/time display with Font Awesome icons
- **Font Support**: DejaVu Sans + Font Awesome 6 for icons
- **Multi-Monitor Ready**: IPC enabled for multi-monitor setups
- **Startup Integration**: Automatic launch via bspwm extraConfig with proper
  process management

### Visual Effects Planning

- **Compositor choice**: Picom already installed and working
- **Transparency strategy**: Selective application to avoid productivity impact
- **Animation balance**: Smooth but not distracting effects

## Resources & References

- [Polybar Documentation](https://polybar.readthedocs.io/)
- [Picom Configuration Guide](https://github.com/yshui/picom)
- [NixOS Polybar Options](https://search.nixos.org/options?channel=unstable&query=polybar)
- [bspwm + Polybar Examples](https://github.com/polybar/polybar/wiki/User-contributed-polybar-configs)
- [mpvpaper for Animated Wallpapers](https://github.com/GhostNaN/mpvpaper)
- [pywal for Dynamic Theming](https://github.com/dylanaraps/pywal)

## Lessons Learned

[To be filled during implementation]
