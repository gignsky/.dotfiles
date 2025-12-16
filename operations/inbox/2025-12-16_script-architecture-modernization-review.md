# Script Architecture Modernization Review

**PRIORITY:** MEDIUM  
**DATE:** 2025-12-16  
**TYPE:** Engineering Enhancement  
**AGENT:** Chief-Engineer-Montgomery-Scott

## Issue Summary
Scripts in `/scripts/` directory should leverage Nix store paths directly instead of relying on PATH, since they're exclusively run as flake packages.

## Background
- All scripts are packaged via `pkgs/scripts.nix` with dependency injection
- Scripts currently assume dependencies are in PATH
- Should use syntax like `${pkgs.lolcat}/bin/lolcat` for direct store paths
- This ensures deterministic execution and eliminates PATH dependency issues

## Required Action
**Engineering Review and Modernization:**
- Audit all scripts in `/scripts/` directory
- Replace command calls with direct Nix store paths where appropriate
- Clean up any legacy PATH-dependent code
- Update packaging in `pkgs/scripts.nix` to match script requirements
- Test all scripts after modernization

## Engineering Notes
**Current Scripts to Review:**
- `inbox-manager.sh` (newly created, should be updated)
- `order-capture.sh` (newly created, should be updated)  
- `system-flake-rebuild.sh`
- `home-manager-flake-rebuild.sh`
- `check-hardware-config.sh`
- `scotty-logging-lib.sh`
- All other `.sh` files in scripts directory

**Implementation Pattern:**
```bash
# Instead of: git add file.txt
# Use: ${pkgs.git}/bin/git add file.txt
```

## Recommendations
1. **Phase 1**: Update newly created scripts (inbox-manager, order-capture)
2. **Phase 2**: Systematic review of all existing scripts
3. **Phase 3**: Update packaging dependencies to match actual usage
4. **Phase 4**: Test suite validation

## Status
**PENDING CAPTAIN REVIEW** - Engineering modernization for script reliability

---
*Filed by: Chief-Engineer-Montgomery-Scott on 2025-12-16*  
*Next Review: During next engineering maintenance window*
