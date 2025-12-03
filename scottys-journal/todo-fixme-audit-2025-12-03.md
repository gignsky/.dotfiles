# TODO/FIXME Audit Report
**Generated**: Stardate 2025-12-03  
**Officer**: Chief Engineer Montgomery Scott  
**Scope**: Repository-wide scan for outstanding TODO and FIXME markers

## Summary
- **Total Items Found**: 13
- **FIXME Items**: 5 (urgent/broken functionality)
- **TODO Items**: 8 (future improvements/optional)

## FIXME Items (High Priority)

### 1. Temporary Unstable Upgrades (flake.nix)
- **Lines 2**: TEMPORARY UNSTABLE UPGRADE FOR OPENCODE TESTING  
- **Lines 1**: TEMPORARY UPGRADE TO MASTER FOR UNSTABLE COMPATIBILITY
- **Assessment**: Temporary testing configurations - need review for permanence vs revert
- **Priority**: Medium (affects stability)

### 2. Library Function Error (lib/default.nix)
- **Issue**: Function fails when child directories don't contain default.nix
- **Assessment**: Could cause build failures in certain configurations  
- **Priority**: High (potential build breakage)

### 3. GitLab Billing Issue (notes.md)
- **Issue**: Extra seat being charged, needs immediate attention
- **Assessment**: Financial impact, requires administrative action
- **Priority**: High (financial)

## TODO Items (Future Improvements)

### 4. WSL Configuration (flake.nix)
- **Issue**: Configuration entrypoint name restrictions in WSL
- **Assessment**: Documentation/improvement opportunity
- **Priority**: Low (documentation)

### 5. Home-manager System Module (flake.nix - 3 instances)
- **Issue**: Consider enabling home-manager as system module for VMs/minimal systems
- **Assessment**: Architecture decision for future consideration
- **Priority**: Low (architectural)

### 6. Output Rules Enhancement (flake.nix)
- **Issue**: Replace current output rules with better-looking alternatives
- **Assessment**: UX improvement opportunity
- **Priority**: Low (cosmetic)

### 7. Username Configuration (Multiple Files)
- **Files**: worker-bee-old-camscountertop.nix, tdarr-node.nix, testbuzz1.nix
- **Issue**: Template placeholders requiring username configuration
- **Assessment**: Template completion for specific host configurations
- **Priority**: Low (host-specific)

## Recommended Actions

### Immediate (Captain Review Required)
1. **GitLab billing issue** - requires administrative action
2. **Library function fix** - potential build stability issue

### Engineering Review
1. **Temporary flake upgrades** - determine permanent vs temporary status
2. **Username templates** - clean up or complete host-specific configurations

### Future Planning
1. **Home-manager architecture** - evaluate system module approach
2. **Output formatting** - research better alternatives
3. **WSL naming** - document limitations or find workarounds

## Clean-up Opportunities
Several TODO items appear to be template artifacts or outdated planning notes that could be:
- Completed and removed
- Updated with current context  
- Converted to proper documentation
- Removed if no longer relevant

---
**Assessment**: Most items are low-priority improvements or template completion.  
**Critical Issues**: 2 items requiring immediate attention (GitLab billing, library function)  
**Maintenance Value**: High - regular audits help maintain code quality
