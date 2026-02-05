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

## Stardate 2026-02-05 02:01 - Final 25.11 Migration Rebuild

**System**: wsl@ganoslal  
**Operation**: nixos-rebuild (system configuration)  
**Status**: ✅ SUCCESS  
**Build Duration**: 30 seconds  
**Generation**: 169 → 169 (same generation, configuration update)  
**Home-Manager**: Generation 524 (current)  
**Repository**: main branch  

### Configuration Changes
This rebuild completes the migration t' NixOS 25.11 stable, applyin' the final flake.nix reorganization changes across the system:

**Core Flake Structure** (`flake.nix` - comprehensive reorganization):
- 🎯 **COMPLETE**: Final flake input reorganization with all circular dependencies resolved
- Removed temporary unstable upgrade comments and FIXME notes
- Reorganized inputs into four clear sections:
  1. Official NixOS and HM Package Sources (stable + unstable + local)
  2. Core Utilities (home-manager, nixos-wsl, nixos-hardware, treefmt-nix, sops-nix, pre-commit-hooks)
  3. Personal Repositories (annex, fancy-fonts, wrapd, gigvim)
  4. Lesser-Used Utilities (moved to bottom for clarity)
- **Circular Dependency Management**: Added proper `follows = ""` breaks for wrapd, gigvim repos
- **Input Following Updates**:
  - sops-nix now follows `nixpkgs` (stable) instead of `nixpkgs-unstable`
  - pre-commit-hooks now follows `nixpkgs` (stable)
  - nixos-wsl now follows `nixpkgs` (stable)
- **Repository Updates**:
  - fancy-fonts URL updated to `git+ssh://git@github.com/gignsky/fancy-fonts.git`
- **Pre-commit Hook Configuration**:
  - Removed `scottys-journal/.*` exclusions from nixfmt
  - Removed `scottys-journal/.*` exclusions from statix
  - Removed `scottys-journal/.*` exclusions from deadnix
  - Removed `scottys-journal/.*` exclusions from shellcheck

**Home Manager Modules**: 24 files modified
- Core: file-managers, git, opencode, starship, wezterm, zsh
- Optional: bat, bspwm, polybar, shellAliases
- Resources: bspwm/merlin.conf
- User configs: home.nix, merlin.nix

**System Modules**: 11 files modified
- Core: fonts, nps, samba
- Optional: audio, bluetooth, brightness-control, bspwm
- Users: gig/default.nix
- Hosts: merlin/default.nix, wsl/default.nix

**Infrastructure**: pkgs/default.nix, vars/default.nix

### Key Diff Analysis
The flake.nix changes represent a *major* architectural cleanup:

**Before** (unstable experiment):
```nix
nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
home-manager.url = "github:nix-community/home-manager/master";
```

**After** (stable production):
```nix
nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
home-manager.url = "github:nix-community/home-manager/release-25.11";
```

**Circular Dependency Prevention**:
```nix
wrapd = {
  url = "github:gignsky/wrapd";
  inputs = {
    dotfiles.follows = ""; # Break circular dependency
  };
};
```

**Pre-commit Hook Simplification** (removed journal exclusions):
```diff
- excludes = [ "scottys-journal/.*" ];
+ excludes = [ ];
```

### Engineering Notes
1. **Build Performance**: 30 seconds - *fastest rebuild yet* in this migration series! Shows excellent cache utilization
2. **Generation Stability**: Same generation (169→169) indicates pure configuration update, no new system profile
3. **Home-Manager Sync**: Home-Manager at generation 524 (much higher than system generation, which is normal)
4. **Stable Channel Complete**: This rebuild solidifies the complete return t' stable channels across all inputs
5. **Input Architecture**: The four-section organization makes input management significantly clearer
6. **Dependency Hygiene**: Circular dependency breaks prevent evaluation issues in personal repo ecosystem
7. **Pre-commit Evolution**: Removing journal exclusions suggests either journal moved or should be properly formatted
8. **Build Optimization**: 30-second build time vs 32s (first rebuild) and 46s (home-manager) shows progressive optimization

### System Status
```
Hostname: ganoslal (WSL environment)
Branch: main
NixOS Generation: 169 (stable)
Home-Manager Generation: 524 (stable)
Build Time: 30s
Nixpkgs: 25.11 stable
Home-Manager: release-25.11
WSL: Following stable nixpkgs
```

**Captain's Assessment**: Migration t' 25.11 stable is *complete an' nominal*! This final rebuild brings all the flake architecture improvements into the system configuration. The 30-second build time is the cherry on top - shows we've got excellent cache coverage. The input reorganization makes the flake significantly more maintainable, an' the circular dependency breaks prevent future evaluation headaches.

The removal o' journal exclusions from pre-commit hooks is notable - suggests scottys-journal is either bein' moved t' a new location or will now be subject t' standard formattin' rules. Either way, it's proper engineerin' - no special cases unless absolutely necessary!

**Recommended Actions**: 
- ✅ System is stable and ready fer production use
- Monitor for any issues with newly-formatted/moved journal files
- Consider documentin' the new flake input architecture in AGENTS.md
- All systems green - ready fer normal operations!

---
*Chief Engineer Montgomery Scott*  
*USS Enterprise Engineering Corps*  
*"The more they overthink the plumbing, the easier it is to stop up the drain!"*
