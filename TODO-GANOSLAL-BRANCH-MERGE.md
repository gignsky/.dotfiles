# TODO: Ganoslal Branch Merge Checklist

**Branch**: `ganoslal-first-fixup`  
**Target**: `main`  
**Purpose**: Complete transition from WSL/Merlin to fully-provisioned Ganoslal multi-monitor desktop  
**Created**: 2026-02-18  
**Status**: 🚧 IN PROGRESS

---

## ⚠️ THIS FILE MUST BE DELETED BEFORE MERGE

This TODO list tracks all remaining work to transition from WSL-based NixOS and Merlin (laptop) to the multi-monitor, well-provisioned Ganoslal desktop system. Once all items are complete and verified, delete this file and merge the branch.

---

## 🎯 CRITICAL: Multi-Monitor & Display Configuration

### Polybar Multi-Monitor Support
- [ ] **TEST**: Verify polybar launches on all 4 monitors
  - [ ] Test on physical hardware (Ganoslal desktop)
  - [ ] Verify each monitor gets its own polybar instance
  - [ ] Check that MONITOR environment variable is properly set
  - [ ] Validate workspace indicators work correctly per monitor
  - [ ] Test polybar restart behavior (super + alt + r)

- [ ] **COMMIT**: Uncommitted polybar.nix changes
  - Current status: Multi-monitor support added but uncommitted
  - File: `home/gig/common/optional/polybar.nix`
  - Changes: Added `monitor = "\${env:MONITOR:}"` and multi-monitor launch script

### Monitor Detection & Configuration
- [ ] **VERIFY**: enable-monitors.sh script functionality
  - [ ] Test 4-monitor detection on boot
  - [ ] Verify monitor positioning is correct:
    - Top row: HDMI-1-0 (left), DP-1 (center), DP-1-1 (right)
    - Bottom: DP-1-2 (main 1440p@120Hz, centered)
  - [ ] Test monitor hot-plug/unplug scenarios
  - [ ] Verify xrandr provider setup for dual-NVIDIA GPUs

- [ ] **TEST**: BSPWM workspace distribution across monitors
  - [ ] Main (DP-1-2): Verify workspaces I, II, III, IV, IX, X, XI, XII
  - [ ] Top-left (HDMI-1-0): Verify workspaces V, VI
  - [ ] Center (DP-1/GTX970): Verify workspaces VII, VIII
  - [ ] Top-right (DP-1-1): Confirm reserved (no workspaces yet)
  - [ ] Test workspace switching with super + 1-9/0/grave
  - [ ] Test moving windows between monitors/workspaces

### Display Resolution & Refresh Rate
- [ ] **VERIFY**: Main monitor settings
  - [ ] Confirm DP-1-2 runs at 2560x1440@120Hz
  - [ ] Verify it's set as primary display
  - [ ] Test refresh rate persistence across reboots

---

## 🖥️ HARDWARE: GPU Configuration Cleanup

### AMD Driver Removal (Legacy from Template/WSL)
- [x] ✅ Remove AMD drivers from ganoslal/default.nix (completed in commit 120c151d)
- [ ] **CLEANUP**: Remove AMD remnants from hardware-configuration.nix
  - [ ] Remove `initrd.kernelModules = [ "amdgpu" ];` (line 26)
  - [ ] Remove `kernelModules = [ "kvm-amd" ];` or update to appropriate (line 28)
  - [ ] Remove AMD kernel parameters:
    - `radeon.si_support=0` (line 35)
    - `amdgpu.si_support=1` (line 36)
  - [ ] Remove AMD microcode update line (line 69)
  - [ ] Update comments that reference AMD GPUs (lines 30-31)
  
  **Why**: Ganoslal is dual-NVIDIA only (GTX 970 + RTX 3060 Ti). AMD config is from hardware-configuration.nix template or previous system.

### NVIDIA Configuration Verification
- [ ] **TEST**: Dual-NVIDIA GPU functionality
  - [ ] Verify both GPUs recognized by system: `nvidia-smi`
  - [ ] Check driver loads correctly: `lsmod | grep nvidia`
  - [ ] Test NVIDIA Control Panel access
  - [ ] Verify X11 sees all 4 monitor outputs
  - [ ] Check kernel modesetting is active

- [ ] **VERIFY**: GPU-specific monitor output mapping
  - [ ] RTX 3060 Ti outputs: HDMI-1-0, DP-1-1, DP-1-2 (verify all work)
  - [ ] GTX 970 output: DP-1 (verify works)
  - [ ] Document any output naming inconsistencies

---

## 🔤 FONTS: Rich Text & Icon Support

### Terminal Font Configuration (WezTerm)
- [ ] **INVESTIGATE**: Current font artifacting issues
  - [ ] Identify specific characters/glyphs rendering incorrectly
  - [ ] Test in OpenCode (VSCode-based) - report specific issues
  - [ ] Test in lazygit - check box-drawing characters and icons
  - [ ] Test in other TUI apps (htop, btop, etc.)
  - [ ] Document which font is actually being used: `fc-match monospace`

- [ ] **VERIFY**: Nerd Font symbol support
  - Current: Only GoMono Nerd Font Mono installed
  - [ ] Check if additional Nerd Font packages needed
  - [ ] Test common icon glyphs render correctly:
    - Powerline symbols (triangles, arrows)
    - Developer icons (git, file types)
    - Material Design icons
    - Font Awesome icons
  - [ ] Verify Nerd Font is actually used in fallback chain

- [ ] **ENHANCE**: Font system configuration
  - Current WezTerm config (wezterm.nix):
    - Font size: 15.0
    - Primary: MonoLisa Mono (with ligatures)
    - Secondary: Cartograph CF (with ligatures)
    - Tertiary: GoMono Nerd Font Mono (with ligatures)
  - [ ] Consider adding nerd-fonts-symbols-only package for icon coverage
  - [ ] Test if "Symbols Nerd Font Mono" explicit fallback helps
  - [ ] Verify harfbuzz features working: `calt`, `liga`, `dlig`, `ss01-ss06`

- [ ] **REVIEW**: System-wide font configuration
  - File: `hosts/common/core/fonts.nix`
  - Current packages: cartograph, artifex, monolisa, nerd-fonts.go-mono, times-newer-roman
  - [ ] Consider adding more comprehensive Nerd Font:
    - Option 1: nerd-fonts.jetbrains-mono (popular, well-tested)
    - Option 2: nerd-fonts.fira-code (excellent ligatures + symbols)
    - Option 3: nerd-fonts.hack (comprehensive coverage)
    - Option 4: Install "nerd-fonts-symbols-only" for universal icon support
  - [ ] Test fontconfig defaultFonts.monospace fallback chain

- [ ] **TEST**: Font rendering quality
  - [ ] Check ligatures render correctly (arrows: `->`, `=>`, `!=`)
  - [ ] Verify box-drawing characters (─│┌┐└┘├┤┬┴┼)
  - [ ] Test unicode symbols (✓✗⚠⚡★☆●○◆◇▲▼◀▶)
  - [ ] Check powerline symbols (        )
  - [ ] Verify emoji rendering (may need separate emoji font)

### Terminal Emulator Configuration
- [ ] **VERIFY**: WezTerm TERM variable
  - Current: `xterm-256color`
  - [ ] Check if wezterm native TERM would help: `wezterm`
  - [ ] Verify true color support: `echo $COLORTERM`
  - [ ] Test: `msgcat --color=test` for color capability

- [ ] **CHECK**: Font cache regeneration
  - [ ] Run: `fc-cache -fv` to rebuild font cache
  - [ ] Verify fonts detected: `fc-list | grep -i "monolisa\|nerd"`
  - [ ] Test after home-manager rebuild

### Application-Specific Issues
- [ ] **OPENCODE**: VSCode font configuration
  - OpenCode inherits WezTerm fonts but may need specific config
  - [ ] Check OpenCode settings for font family overrides
  - [ ] Verify integrated terminal uses WezTerm fonts
  - [ ] Test if OpenCode needs explicit Nerd Font specification

- [ ] **LAZYGIT**: TUI rendering validation
  - [ ] Test box-drawing characters in lazygit UI
  - [ ] Verify git status icons render correctly
  - [ ] Check branch tree symbols display properly
  - [ ] Confirm all UI elements are readable

### Reference Documentation
- [ ] **REVIEW**: Prior font work in annex
  - Found references to:
    - 2025-12-23: Ligature support added (harfbuzz features)
    - 2025-12-16: Font size increased 11→12 (now 15)
    - 2025-12-14: Font fallback optimization
    - 2025-12-09: MonoLisa Variable made primary
  - [ ] Check if previous font issues were fully resolved
  - [ ] Document any recurring patterns

### Recommended Solution Path
**Priority Order**:
1. First: Identify exact rendering issues (screenshot/describe)
2. Second: Verify current font is actually being used (`fc-match`)
3. Third: Test with explicit Symbols Nerd Font fallback
4. Fourth: Add comprehensive Nerd Font if GoMono insufficient
5. Fifth: Rebuild font cache and test
6. Sixth: Document solution in annex

**Quick Test Commands**:
```bash
# Check active font
fc-match monospace

# List installed Nerd Fonts
fc-list | grep -i nerd

# Test unicode in terminal
echo "→ ✓ ★  "

# Verify WezTerm font config
wezterm ls-fonts

# Rebuild font cache
fc-cache -fv
```

---

## 🎨 VISUAL: Wallpaper & Compositor

### Wallpaper Configuration
- [ ] **TEST**: Current wallpaper on all 4 monitors
  - Current: `wallpapers/tolkien/desktop/4k-doors-of-durin-horizontal.webp`
  - [ ] Verify appears on all monitors
  - [ ] Check scaling behavior (--bg-scale)
  - [ ] Test super + shift + w (wallpaper refresh)

- [ ] **DECIDE**: Wallpaper rotation strategy (from TODO line 39)
  - TODO comment: "figure out how to make these rotate through the tolkien folder"
  - Options:
    - [ ] Simple rotation script with systemd timer
    - [ ] Use variety or nitrogen for GUI management
    - [ ] Implement custom Nushell rotation script
  - [ ] Remove or implement TODO comment in bspwm.nix line 39

### Compositor (Picom)
- [ ] **VERIFY**: Picom runs correctly with dual-NVIDIA
  - [ ] Check picom starts: `pgrep picom`
  - [ ] Verify --backend glx works with NVIDIA
  - [ ] Test window transparency and effects
  - [ ] Check for screen tearing or performance issues

---

## ⚙️ DESKTOP ENVIRONMENT: BSPWM Configuration

### Window Manager Settings
- [ ] **TEST**: BSPWM settings on multi-monitor setup
  - [ ] Verify border_width = 5 is visible on all monitors
  - [ ] Test window_gap = 13 spacing
  - [ ] Check top_padding = 30 reserves space for polybar
  - [ ] Verify focus behavior (pointer_follows_focus = true)

### Application Rules
- [ ] **TEST**: Application workspace assignments
  - [ ] Discord → workspace IX (desktop ^9)
  - [ ] YouTube Music → workspace IX
  - [ ] Test `follow = true` behavior

### Hotkeys (sxhkd)
- [ ] **TEST**: All keybindings function correctly
  - [ ] Terminal: super + Return
  - [ ] App launcher: super + space
  - [ ] Help window: super + ?
  - [ ] Window management: super + w, super + f, super + t
  - [ ] Desktop switching: super + 1-9/0/grave (11 desktops)
  - [ ] Screenshots: Print, super + Print
  - [ ] Volume controls: XF86Audio{Raise,Lower}Volume, XF86AudioMute

- [ ] **REMOVE/UPDATE**: Laptop-specific brightness controls
  - Lines 239-247 have brightness controls for "Framework 16 function keys"
  - Ganoslal is a desktop - these may not be needed
  - [ ] Test if brightness controls work (external monitor brightness?)
  - [ ] Consider removing or commenting out if not applicable

---

## 🔧 SYSTEM: Configuration & Services

### Tailscale
- [x] ✅ Disabled temporarily (commit ce1274a4)
- [ ] **DECIDE**: Re-enable Tailscale or keep disabled?
  - Current: `tailscale.enable = false;`
  - [ ] Determine if Ganoslal needs VPN connectivity
  - [ ] If yes: Re-enable and configure
  - [ ] If no: Document why it's disabled

### Bootloader
- [ ] **VERIFY**: systemd-boot configuration
  - [ ] Test boot menu appears correctly
  - [ ] Verify EFI variables are accessible
  - [ ] Check generations show up in boot menu

### Filesystem
- [ ] **REVIEW**: Commented ZFS configuration (lines 96-109)
  - Large commented block for ZFS filesystems
  - [ ] Confirm Ganoslal uses ext4 (current: line 43-44)
  - [ ] Decide: Remove commented ZFS config or document purpose
  - [ ] If planning ZFS migration: Document in separate enhancement protocol

### Network Configuration
- [ ] **TEST**: NetworkManager functionality
  - [ ] Verify ethernet connectivity
  - [ ] Test if wifi hardware exists (desktop may not have wifi)
  - [ ] Check DNS resolution works

---

## 📦 PACKAGES & SOFTWARE

### Desktop Applications
- [ ] **VERIFY**: All ganoslal.nix packages install correctly
  - [ ] youtube-music
  - [ ] plex-desktop
  - [ ] remmina (remote desktop)
  - [ ] bitwarden-desktop
  - [ ] discord
  - [ ] gpu-viewer (test with dual-NVIDIA)

### BSPWM Tools
- [ ] **TEST**: Additional bspwm packages from bspwm.nix
  - [ ] dmenu (application launcher alternative)
  - [ ] xclip (clipboard)
  - [ ] maim (screenshots)
  - [ ] xdotool (window manipulation)
  - [ ] nitrogen (wallpaper setter alternative)
  - [ ] feh (current wallpaper setter)

---

## 🧪 TESTING: System Validation

### Boot & Login Testing
- [ ] **TEST**: Complete boot cycle
  - [ ] System boots without errors
  - [ ] All 4 monitors detected at login
  - [ ] X11 starts correctly with BSPWM
  - [ ] Polybar appears on all monitors
  - [ ] Wallpaper loads on all monitors

### Multi-Monitor Workflow Testing
- [ ] **TEST**: Real-world multi-monitor usage
  - [ ] Open windows on each monitor
  - [ ] Move windows between monitors
  - [ ] Switch workspaces across monitors
  - [ ] Test fullscreen on each monitor
  - [ ] Verify focus behavior across monitors

### Performance Testing
- [ ] **TEST**: System performance with all monitors active
  - [ ] Check GPU temperatures: `nvidia-smi`
  - [ ] Monitor system load
  - [ ] Test compositor performance (no lag/tearing)
  - [ ] Verify no memory leaks from polybar instances

### Stability Testing
- [ ] **TEST**: Extended usage stability
  - [ ] Run system for several hours
  - [ ] Test BSPWM restart: super + alt + r
  - [ ] Test monitor power save/wake cycles
  - [ ] Verify workspace persistence

---

## 📝 DOCUMENTATION

### Configuration Documentation
- [ ] **DOCUMENT**: Final monitor layout in comments
  - Update ganoslal.conf with actual tested configuration
  - Document any xrandr quirks discovered
  - Note any monitor output name inconsistencies

- [ ] **DOCUMENT**: Hardware specifications
  - Finalize GPU configuration documentation in nvidia.nix
  - Document any NVIDIA driver issues encountered
  - Note any X11 configuration tweaks required

### Commit Messages
- [ ] **IMPROVE**: Commit message quality (noted in branch analysis)
  - Current commits lack detailed context
  - Next commit should follow Lord Gig's Standards of Commitence
  - Include: What changed, why changed, testing performed

### Knowledge Base
- [ ] **OPTIONAL**: Create multi-monitor setup guide
  - Document dual-NVIDIA + multi-monitor configuration process
  - Include troubleshooting steps
  - File in engineering/enhancement-protocols/ or docs/guides/

---

## 🔄 MERGE PREPARATION

### Pre-Merge Checklist
- [ ] **VERIFY**: All critical TODOs above are complete
- [ ] **VERIFY**: All tests pass
- [ ] **COMMIT**: All uncommitted changes (polybar.nix)
- [ ] **CLEAN**: Hardware configuration cleaned of AMD references
- [ ] **TEST**: Final full system rebuild succeeds
  - [ ] NixOS rebuild: `just rebuild` or `scripts/system-flake-rebuild.sh`
  - [ ] Home-manager rebuild: `just home` or `scripts/home-manager-flake-rebuild.sh`
  - [ ] Both complete without errors

### Final Validation
- [ ] **TEST**: Reboot and verify everything still works
- [ ] **VERIFY**: No remaining TODOs in code (except SEP-001 wallpaper rotation)
- [ ] **REVIEW**: Git history is clean and understandable
- [ ] **DOCUMENT**: Update scottys-journal/logs/ with final status

### Merge Execution
- [ ] **DECISION**: Merge strategy
  - Option A: `git merge ganoslal-first-fixup` (preserves history)
  - Option B: `git rebase -i main` then merge (cleaner history)
  - Recommendation: Regular merge to preserve full development history

- [ ] **EXECUTE**: Merge to main
  ```bash
  git checkout main
  git merge ganoslal-first-fixup
  git push origin main
  ```

- [ ] **DELETE**: This TODO file
  ```bash
  git rm TODO-GANOSLAL-BRANCH-MERGE.md
  git commit -m "chore: remove completed Ganoslal merge TODO list"
  ```

- [ ] **CLEANUP**: Delete feature branch (optional)
  ```bash
  git branch -d ganoslal-first-fixup
  git push origin --delete ganoslal-first-fixup
  ```

---

## 📊 COMPLETION TRACKING

**Current Progress**: 
- Hardware foundation: ✅ Complete (AMD removed, NVIDIA configured)
- BSPWM configuration: ✅ Base complete, needs testing
- Polybar multi-monitor: ⚠️ Implemented but uncommitted
- Multi-monitor detection: ✅ Script exists, needs testing
- System testing: ❌ Not started
- Documentation: ⚠️ Partial

**Estimated Remaining Work**: 3-4 hours (mostly testing and validation)

**Blockers**: 
1. Physical hardware access required for multi-monitor testing
2. Polybar commit pending test results

---

## 🎯 SUCCESS CRITERIA

This branch is ready to merge when:
1. ✅ All 4 monitors detected and configured correctly
2. ✅ Polybar appears on all 4 monitors
3. ✅ BSPWM workspaces distributed correctly across monitors
4. ✅ All hotkeys function as expected
5. ✅ System stable for extended usage
6. ✅ Hardware configuration cleaned of AMD remnants
7. ✅ All uncommitted changes committed with proper messages
8. ✅ This TODO file deleted

---

**Last Updated**: 2026-02-18 by Chief Engineer Montgomery Scott  
**Next Review**: After physical hardware testing begins  
**Contact**: Open issue in fleet operations if questions arise

*"Ye cannae merge what ye havnae tested!" - Chief Engineer Scott*
