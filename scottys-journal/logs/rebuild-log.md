# Chief Engineer's Rebuild Log
*Engineering Journal - System Rebuild Operations*

---

## Stardate 2026-02-05 01:42 - Major Flake Reorganization & NixOS 25.11 Upgrade

**System**: wsl@ganoslal  
**Operation**: nixos-rebuild (system configuration)  
**Status**: ✅ SUCCESS  
**Build Duration**: 32 seconds  
**Generation**: 169 → 169 (same generation, configuration update)  
**Home-Manager**: Generation 272 (current)  
**Repository**: main branch @ `83c350ea`  

### Configuration Changes
This rebuild included a *major* flake reorganization - one o' the biggest structural changes I've seen in a while! Here's what changed:

**Core Flake Structure** (`flake.nix`):
- 🎯 **PRIMARY**: Upgraded from nixpkgs-unstable back to **nixos-25.11 stable**
- 🎯 **PRIMARY**: Upgraded home-manager from master back to **release-25.11**
- Reorganized inputs into logical sections:
  - Official NixOS and HM sources
  - Utilities (separated lesser-used to bottom)
  - Personal repositories
- Added circular dependency breaks for personal repos (wrapd, gigvim, etc.)
- Cleaned up commented-out experimental unstable configs
- Updated fancy-fonts URL to new repository location
- Adjusted sops-nix to follow stable nixpkgs instead of unstable
- Updated pre-commit-hooks to follow nixpkgs for consistency
- Removed journal exclusions from pre-commit hooks (nixfmt, statix, deadnix, shellcheck)

**Home Manager Configurations**:
- `home/gig/common/core/file-managers.nix`
- `home/gig/common/core/git.nix`
- `home/gig/common/core/opencode.nix`
- `home/gig/common/core/starship.nix`
- `home/gig/common/core/wezterm.nix`
- `home/gig/common/core/zsh.nix`
- `home/gig/common/optional/bat.nix`
- `home/gig/common/optional/bspwm.nix`
- `home/gig/common/optional/polybar.nix`
- `home/gig/common/optional/shellAliases.nix`
- `home/gig/common/resources/bspwm/merlin.conf`
- `home/gig/home.nix`
- `home/gig/merlin.nix`

**System Configurations**:
- `hosts/common/core/fonts.nix`
- `hosts/common/core/nps.nix`
- `hosts/common/core/samba.nix`
- `hosts/common/optional/audio.nix`
- `hosts/common/optional/bluetooth.nix`
- `hosts/common/optional/brightness-control.nix`
- `hosts/common/optional/bspwm.nix`
- `hosts/common/users/gig/default.nix`
- `hosts/merlin/default.nix`
- `hosts/wsl/default.nix`

**Package & Variable Definitions**:
- `pkgs/default.nix`
- `vars/default.nix`

### Engineering Notes
1. **Stability Return**: This marks the return t' NixOS 25.11 stable after the temporary unstable experiment fer OpenCode testing
2. **Circular Dependencies**: Added proper circular dependency breaks fer personal repositories - this prevents evaluation issues when repos reference each other
3. **Pre-commit Cleanup**: Removed scottys-journal exclusions from formatters/linters - suggests journal is either moved or should be properly formatted
4. **Build Performance**: 32-second rebuild is *exceptional* performance fer changes o' this magnitude - shows the Nix binary cache is workin' beautifully
5. **Generation Stability**: Same generation number (169→169) indicates this was a configuration-only change with no new system profile created

### System Status
```
Hostname: ganoslal (WSL environment)
Branch: main
Commit: 83c350ea5cc1fd80bc92545989bc65f3d479a238
NixOS Generation: 169 (stable)
Home-Manager Generation: 272 (stable)
Build Time: 32s
Nixpkgs: 25.11 stable
```

**Captain's Assessment**: All systems nominal! The upgrade t' 25.11 stable went smooth as silk, an' the flake reorganization makes the structure much more maintainable. This is proper engineerin' work here - consolidatin' back t' stable after testin' with unstable, cleanin' up the input structure, an' preparin' the systems fer long-term stability.

**Recommended Actions**: None required - system is stable and operational.

---

## Stardate 2026-02-05 01:55 - Home-Manager Rebuild Post Flake Reorganization

**System**: wsl@ganoslal  
**Operation**: home-manager rebuild  
**Status**: ✅ SUCCESS  
**Build Duration**: 46 seconds  
**Generation**: 272 → 273  
**NixOS Generation**: 169 (current)  
**Repository**: main branch (post-flake-reorganization)  

### Configuration Changes
This home-manager rebuild picks up all the changes from the previous major flake reorganization, now applyin' them to the user environment:

**Core Home-Manager Modules**:
- `flake.nix` - Major flake input reorganization & 25.11 stable upgrade
- `home/gig/common/core/file-managers.nix`
- `home/gig/common/core/git.nix`
- `home/gig/common/core/opencode.nix`
- `home/gig/common/core/starship.nix`
- `home/gig/common/core/wezterm.nix`
- `home/gig/common/core/zsh.nix`

**Optional Modules**:
- `home/gig/common/optional/bat.nix`
- `home/gig/common/optional/bspwm.nix`
- `home/gig/common/optional/polybar.nix`
- `home/gig/common/optional/shellAliases.nix`

**User & Host Configurations**:
- `home/gig/common/resources/bspwm/merlin.conf`
- `home/gig/home.nix`
- `home/gig/merlin.nix`

**System-Level Files** (tracked changes, applied to user env):
- `hosts/common/core/fonts.nix`
- `hosts/common/core/nps.nix`
- `hosts/common/core/samba.nix`
- `hosts/common/optional/audio.nix`
- `hosts/common/optional/bluetooth.nix`
- `hosts/common/optional/brightness-control.nix`
- `hosts/common/optional/bspwm.nix`
- `hosts/common/users/gig/default.nix`
- `hosts/merlin/default.nix`
- `hosts/wsl/default.nix`

**Infrastructure**:
- `pkgs/default.nix`
- `vars/default.nix`

### Key Flake Changes Applied
From the `flake.nix` diff:
- **Nixpkgs**: Upgraded from `nixos-unstable` → `nixos-25.11` (stable)
- **Home-Manager**: Upgraded from `master` → `release-25.11`
- **Input Organization**: Reorganized into logical sections (Official/Utilities/Personal/Lesser-Used)
- **Circular Dependencies**: Added dependency breaks fer personal repos (wrapd, gigvim)
- **Fancy Fonts**: Updated URL to new repository location `git+ssh://git@github.com/gignsky/fancy-fonts.git`
- **Sops-nix**: Now follows `nixpkgs` (stable) instead of `nixpkgs-unstable`
- **Pre-commit-hooks**: Now follows `nixpkgs` for consistency
- **Pre-commit Config**: Removed `scottys-journal/.*` exclusions from formatters/linters

### Engineering Notes
1. **Build Time**: 46 seconds is reasonable fer a home-manager rebuild of this scope - bit slower than system rebuild (32s) but that's expected with all the user-space packages
2. **Generation Increment**: Proper generation bump (272→273) indicates new home-manager profile created with all changes
3. **Stable Channel**: This solidifies the return t' the stable 25.11 channel across both system and user environments
4. **Comprehensive Changes**: The number o' files changed (24 total) shows this was a thorough configuration update touchin' nearly every aspect o' the user environment
5. **Pre-commit Implications**: Removed journal exclusions suggest either the journal location changed or it should now be properly formatted by standard tools

### System Status
```
Hostname: ganoslal (WSL environment)
Branch: main
NixOS Generation: 169 (stable)
Home-Manager Generation: 273 (NEW)
Build Time: 46s
Nixpkgs: 25.11 stable
Home-Manager: release-25.11
```

**Captain's Assessment**: Home-manager rebuild successful! User environment is now fully aligned with the 25.11 stable channel. The 46-second build time shows we're pullin' most packages from cache - no major recompilation needed. All systems are now operatin' on stable channels with proper input organization an' dependency management.

**Recommended Actions**: 
- Monitor first login fer any configuration issues with the updated modules
- Verify OpenCode configuration still works properly with stable home-manager
- Test shell aliases, starship prompt, and wezterm configuration

---
*Chief Engineer Montgomery Scott*  
*USS Enterprise Engineering Corps*  
*"The more they overthink the plumbing, the easier it is to stop up the drain!"*
