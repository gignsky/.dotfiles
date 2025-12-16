# Missing Script Packages Resolution

**PRIORITY:** MEDIUM  
**DATE:** 2025-12-16  
**TYPE:** Engineering Fix  
**AGENT:** Chief-Engineer-Montgomery-Scott

## Issue Summary
Several justfile commands reference script packages that are missing or commented out, causing command failures after implementing automatic script inheritance.

## Background
- ✅ **Automatic script inheritance implemented successfully**
- ⚠️ **Missing/disabled scripts discovered during implementation**
- 🔴 **Breaking justfile commands identified**

## Affected Commands & Scripts

### Missing Script Packages
1. **`flake-build`** → Used by `just build` command
   - **Status**: Not defined in `scripts.nix`
   - **Impact**: `just build <args>` fails
   - **Action**: Create script package or update justfile

2. **`bootstrap-nixos`** → Used by `just bootstrap` command  
   - **Status**: Not defined in `scripts.nix`
   - **Impact**: `just bootstrap <args>` fails
   - **Action**: Create script package or update justfile

### Commented Out Scripts
3. **`package-script`** → Used by `just package-script` command
   - **Status**: Commented out in `scripts.nix` (lines 154-170)
   - **Impact**: `just package-script` fails
   - **Action**: Uncomment and test, or update justfile

4. **`run-iso-vm`** → Used by ISO VM commands
   - **Status**: Commented out in `scripts.nix` (lines 141-150)  
   - **Impact**: VM-related commands may fail
   - **Action**: Uncomment and test, or update justfile

## Required Actions

### Phase 1: Investigation (Immediate)
- **Verify Script Existence**: Check if missing scripts exist in `scripts/` directory
- **Command Usage Analysis**: Determine which commands are actively used
- **Dependency Assessment**: Understand what these scripts were supposed to do

### Phase 2: Resolution (This Week)
Choose one approach per missing script:

#### **Option A: Create Missing Script Packages**
```nix
# Add to scripts.nix
flake-build = makeScriptPackage {
  name = "flake-build";
  scriptPath = ../scripts/flake-build.sh;
  dependencies = with pkgs; [ bash nix ];
  description = "Builds specific flake targets with proper error handling";
};

bootstrap-nixos = makeScriptPackage {
  name = "bootstrap-nixos";  
  scriptPath = ../scripts/bootstrap-nixos.sh;
  dependencies = with pkgs; [ bash git nix ];
  description = "Bootstraps a new NixOS installation with dotfiles";
};
```

#### **Option B: Update Justfile Commands**
```just
# Replace missing script calls with direct implementations
build *args:
    just pre-build
    nix build {{args}}  # Direct nix command instead of script
    just post-build

bootstrap *args:
    just dont-fuck-my-build
    # Direct bootstrap implementation or alternative approach
```

#### **Option C: Hybrid Approach**
- Uncomment working scripts (`package-script`, `run-iso-vm`)
- Create essential missing scripts (`flake-build`, `bootstrap-nixos`)
- Update justfile for any remaining issues

## Engineering Notes
**Root Cause Analysis:**
- Scripts were referenced in justfile but never properly packaged
- Some scripts were disabled/commented without updating dependent commands
- Manual inheritance list masked these missing dependencies

**Impact Assessment:**
- ✅ **No impact on core workflows** (rebuild, home, inbox commands work)
- ⚠️ **Medium impact on build workflows** (just build fails)
- ⚠️ **Low impact on bootstrap workflows** (just bootstrap fails)  
- 🔍 **Unknown impact on ISO/VM workflows** (needs testing)

**Quality Improvement:**
- Automatic inheritance exposes hidden dependencies
- Forces proper script package maintenance
- Prevents future "phantom reference" issues

## Recommendations
1. **Immediate**: Investigate actual script file existence in `scripts/` directory
2. **Short-term**: Uncomment working scripts, create essential missing ones
3. **Medium-term**: Audit all justfile→package references for consistency
4. **Long-term**: Add CI checks to prevent script/justfile drift

## Status
**PENDING CAPTAIN REVIEW** - Script packaging consistency fix required

---
*Filed by: Chief-Engineer-Montgomery-Scott on 2025-12-16*  
*Next Review: After Captain prioritizes resolution approach*
