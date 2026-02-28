# Engineering Log: Home-Manager Rebuild - Generation 149
**Stardate**: 2026-02-28  
**Host**: merlin  
**Branch**: fixing-fucked-fonts  
**Chief Engineer**: Montgomery Scott  

---

## Rebuild Summary
**Generation Transition**: 148 → 149  
**Build Duration**: 18 seconds  
**Status**: ✅ **SUCCESS**  

Och, she's runnin' smooth as silk now! A clean rebuild with no hiccups—just the way I like 'em.

---

## Configuration Changes

### Files Modified
Three configuration files were adjusted fer this rebuild:

1. **home/gig/common/core/wezterm.nix**
2. **home/gig/common/optional/picom.nix**
3. **hosts/common/core/fonts.nix**

---

## Detailed Change Analysis

### 1. WezTerm Configuration Cleanup (`home/gig/common/core/wezterm.nix`)

**Nature**: Code cleanup and comment removal  
**Impact**: Configuration simplification without functional changes

Removed experimental font testing comments and temporary font rendering overrides:
- Deleted commented JetBrains Mono Nerd Font testing configuration
- Removed HarfBuzz features configuration (`calt`, `liga`, `dlig`)
- Removed FreeType rendering target overrides

**Engineering Assessment**:  
This be a proper cleanup after font testing concluded. The commented-out sections were experimental scaffolding that's no longer needed. The base font size (15.0) and window padding remain unchanged, maintainin' functional stability.

**Lines Removed**: 9 lines (comments and font rendering configuration)

---

### 2. Picom Compositor Adjustments (`home/gig/common/optional/picom.nix`)

**Nature**: Transparency and opacity tuning  
**Impact**: Visual appearance changes for window compositing

**Opacity Adjustments**:
- `active-opacity`: 0.83 → **0.90** (increased transparency for focused windows)
- `frame-opacity`: 0.79 → **0.50** (significantly increased transparency for borders)
- `inactive-opacity`: 0.75 (unchanged)

**Application-Specific Rules**:  
Commented out all application-specific opacity rules, includin':
- Firefox, Chromium (were set to 100% opaque)
- WezTerm (was set to 83%)
- Rofi (was set to 75%)
- VS Code/editors (was set to 83%)
- mpv, VLC (were set to 100%)

**Engineering Assessment**:  
This moves from application-specific opacity tuning to a universal approach. The active window opacity increase (0.83 → 0.90) provides better readability fer focused work, while the dramatic frame opacity reduction (0.79 → 0.50) creates a lighter, less intrusive window border aesthetic. The commented rules suggest this be a transitional state—possibly testin' whether universal rules provide better visual consistency than per-application overrides.

**Fade Settings**: Remain enabled and unchanged

---

### 3. Font Stack Reordering (`hosts/common/core/fonts.nix`)

**Nature**: Primary monospace font priority change  
**Impact**: System-wide monospace font rendering preference

**Monospace Font Stack Change**:
```
BEFORE:
1. Cartograph CF
2. MonoLisa Variable
3. Artifex CF
4. GoMono Nerd Font Mono

AFTER:
1. MonoLisa Variable  ← PROMOTED
2. Cartograph CF      ← DEMOTED
3. Artifex CF
4. GoMono Nerd Font Mono
```

**Engineering Assessment**:  
MonoLisa Variable has been promoted to primary monospace font, with Cartograph CF movin' to secondary fallback position. This be a significant aesthetic change fer terminal work, code editors, and any application using the system's default monospace font. Given the branch name (`fixing-fucked-fonts`), this reordering be part of ongoing font rendering optimization work.

The rest o' the font stack (Artifex CF and GoMono Nerd Font) remain in their fallback positions, maintainin' Nerd Font glyph support.

---

## Technical Context

### Branch Operation
Currently operatin' on the **`fixing-fucked-fonts`** branch, indicatin' this rebuild be part of an active font rendering and visual aesthetics improvement initiative.

### Build Performance
18-second build time be well within normal parameters fer home-manager configuration of this scope. No compilation bottlenecks or dependency resolution delays observed.

### Cross-File Relationships
The changes across these three files suggest a coordinated effort:
1. WezTerm cleanup removes old font experiments
2. Font stack reordering changes primary monospace rendering
3. Picom adjustments tune transparency fer the new visual aesthetic

---

## System State Post-Rebuild

**Home-Manager Generation**: 149  
**Configuration Integrity**: Verified  
**Service Restarts**: Automatic per home-manager activation  
**User Session Impact**: Minor (transparency and font changes visible immediately)

---

## Engineering Notes

1. **Font Testing Phase Complete**: The removal of WezTerm font testing comments suggests the experimental phase has concluded and decisions have been made.

2. **Transparency Philosophy Shift**: Movin' from application-specific opacity rules to universal settings simplifies maintenance and provides visual consistency. Monitor user feedback on this approach.

3. **MonoLisa Promotion**: The font stack reordering elevates MonoLisa Variable to primary status. This be a deliberate aesthetic choice that'll affect all monospace rendering system-wide.

4. **Clean Rebuild**: No errors, no warnings, no pre-commit hook issues. She's a textbook example o' how a rebuild should go.

---

## Recommendations

1. **Monitor Font Rendering**: With MonoLisa now primary, keep an eye on glyph coverage and Nerd Font icon rendering. The GoMono fallback should catch any glyphs MonoLisa doesn't provide.

2. **Transparency Feedback**: The new picom settings be more aggressive (especially frame-opacity at 0.50). If borders become too hard to see, consider bumpin' it back up to 0.65-0.70 range.

3. **Branch Merge Readiness**: This rebuild be clean and stable. Once visual tuning be finalized, this branch should be ready fer merge to main.

---

**Chief Engineer's Signature**: Montgomery Scott  
**Timestamp**: 2026-02-28  
**Status**: Configuration stable, all systems nominal

---

*"The right tool fer the right job, and the right font fer the right code!"*  
— Chief Engineer Montgomery Scott
