# Repository Architecture Principles

## Lord Gig's Configuration Structure Philosophy
*Original explanation provided by Lord Gig - 2025-01-28*

Make sure that when possible, if the package doesn't need to be installed to a certain level it should be called at a lower level for example, a utility can be at various levels with descending levels of constriction? that might not be the right word, basically this order:

**Hierarchy (descending specificity):**
1. host-specific `hosts/$HOSTNAME` 
2. multi-host I `hosts/common/core/*` 
3. multi-host II `hosts/common/optional` 
4. user-space (home-manager) multi-host I & II (replicating the same properties as the multi-host I & II on the device-level `hosts/` folder) 
5. script-space 
6. package-space 
7. BACK TO host-specific

### File Tree Structure Explanation

```
hosts/
├── host-1/
│   ├── default.nix          # host-specific (formerly configuration.nix)
│   └── hardware-configuration.nix  # imported from default.nix, ideally not touched often
└── common/
    ├── core/                # multi-host I
    │   ├── default.nix      # automatically imports all items in current core/ dir
    │   ├── core-item1.nix
    │   └── core-item2.nix
    └── optional/            # multi-host II
        ├── opt-item1.nix    # imported manually in `hosts/$HOST/default.nix`
        └── opt-item2.nix
```

### Key Principles

**Host Configuration Strategy:**
- The `hosts/$HOSTNAME/default.nix` file is the heart of the host-level configuration
- Currently has a few core settings defined directly there but try to put as much in the core/ and optional/ common/ directories so they can be shared between as many hosts as possible without duplication
- Each host grabs the core/ folder and each host takes the items it needs from the optional/ folder as imported files
- *Note: passingly familiar with nix lang's options, and have been considering converting this current system into something that takes advantage of that but don't know the best way to go about it and would appreciate suggestions*

**Installation Level Decision Making:**
- Items should only be installed in the hosts/ directory if they are required for operation across the whole system in order to perform their task
- Any item that does not meet that threshold and can be installed without too much hassle elsewhere should be installed in user-space with home-manager

**Home Manager Structure:**
- `home/` currently mimics the structure of hosts and could be improved in similar ways

**Scripts & Package Philosophy:**
- The 'scripts' include when one writes a string block inside of .nix files that will later be embedded either in a bash file or script that could be read from another program
- That type of 'file/script' cannot be avoided though in those cases when possible the file should be referenced (if inside -- or imported by (as intended) -- a .nix file)
- Then the `$pkgs.pkgs/bin/pkg` should be used in place of calling `pkg` and thus requiring the package to be installed a layer up the chain if not necessary

**Actual Script Policy:**
- Should be written as .sh files in the scripts/ folder 
- Then they should be packaged in the pkgs/ directory as a writeShellScriptBin
- So that if this script needs to be called from anywhere else it simply can use the pkgs.NAME_OF_SCRIPT_BINARY as it would any other program

**Package Dependencies:**
- Packages should just always include all their dependents and no more
- Sometimes however a custom patch or package is needed and this is why the sequence loops around on itself
- Sometimes in order to avoid duplication it becomes necessary to write up a custom package for easier reference elsewhere

---

## Chief Engineer's Analysis & Recommendations
*Analysis by Chief Engineer Montgomery Scott - 2025-01-28*

### Current Architecture Assessment

Lord Gig's layered approach follows excellent separation of concerns principles. The hierarchy creates clear boundaries for where different types of configurations should live, minimizing duplication while maximizing reusability.

### NixOS Options System Integration

**Recommendation for Options Migration:**
```nix
# Example: hosts/common/options/bspwm-options.nix
{ lib, ... }:
{
  options.lordGig.desktop.bspwm = {
    enable = lib.mkEnableOption "bspwm window manager";
    
    keybindings = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      description = "Custom keybindings for sxhkd";
    };
    
    wallpaper = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to wallpaper image";
    };
  };
}
```

**Benefits of Options Approach:**
- Type safety and validation
- Built-in documentation via `description` fields  
- Conditional module loading via `config = lib.mkIf cfg.enable { ... }`
- Override capabilities for host-specific customization
- Better error messages when misconfigured

### Package Reference Best Practices

**Current Good Practice Example:**
```nix
# Instead of requiring 'feh' to be installed system-wide
"super + shift + w" = ''
  if [ -f "$HOME/.background-image" ]; then
    ${pkgs.feh}/bin/feh --bg-scale "$HOME/.background-image"
  fi
'';
```

**Script Packaging Pattern:**
```nix
# pkgs/scripts.nix
wallpaper-refresh = pkgs.writeShellScriptBin "wallpaper-refresh" ''
  if [ -f "$HOME/.background-image" ]; then
    ${pkgs.feh}/bin/feh --bg-scale "$HOME/.background-image"
  fi
'';
```

### Home Manager Structure Improvements

**Suggested Migration Pattern:**
```
home/
├── gig/
│   ├── common/
│   │   ├── core/           # Essential user configs
│   │   ├── optional/       # Feature-specific configs  
│   │   └── options/        # Home-manager options definitions
│   └── profiles/           # Host-specific user profiles
│       ├── merlin.nix
│       ├── ganoslal.nix
│       └── spacedock.nix
```

### Dependency Management Strategy

**Layer-Appropriate Installation Guidelines:**

1. **System-level (`hosts/`)**: Drivers, system services, kernel modules
2. **User-level (`home/`)**: Desktop applications, development tools, personal utilities  
3. **Script-level**: Embedded dependencies via `${pkgs.tool}/bin/tool`
4. **Package-level**: Self-contained with all dependencies declared

**Custom Package Creation Triggers:**
- Multiple modules need same patched version
- Complex build requirements that benefit from abstraction
- Reusable component across different hosts/users

### Migration Strategy Recommendations

1. **Phase 1**: Convert existing modules to use options system
2. **Phase 2**: Consolidate duplicate configurations using new options
3. **Phase 3**: Migrate scripts to proper packages in `pkgs/`
4. **Phase 4**: Implement host profiles using options system

This approach maintains Lord Gig's excellent architectural principles while adding the robustness and flexibility of NixOS's options system.
