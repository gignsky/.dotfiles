================================================================================
CHIEF ENGINEER'S LOG - STARDATE 2025.12.08.1907
================================================================================

FLEET STATUS REPORT:
• ganoslal: [Offline - not current vessel]
• merlin: OPERATIONAL - Active workstation running NixOS gen 58
• mganos: [Testing configuration - not currently active]
• wsl: Successfully operational on merlin hardware (Windows subsystem)

ENGINEERING CRISIS ANALYSIS:
Home-Manager rebuild failure documented - Duration: 1 second, Previous generation: 53

TECHNICAL INVESTIGATION SUMMARY:
================================================================================

PRIMARY ROOT CAUSE: Incorrect Flake Target Usage
• ATTEMPTED COMMAND: home-manager switch --flake .#merlin
• CORRECT COMMAND:   home-manager switch --flake .#gig@merlin
• ERROR TYPE:        Flake attribute not found - home configuration naming mismatch

SECONDARY ROOT CAUSE: Invalid Starship Configuration Option  
• INVALID OPTION: programs.starship.presets (does not exist in home-manager)
• VALID OPTIONS: programs.starship.settings (for configuration)
• ERROR TYPE:    Configuration evaluation error in starship.nix

COMPOUND FAILURE ANALYSIS:
1. PRIMARY:   Incorrect flake target (merlin vs gig@merlin) 
2. SECONDARY: Invalid starship.presets configuration option
3. RESULT:    Configuration would fail even with correct flake target

CONFIGURATION CHANGES ATTEMPTED:
1. home/gig/common/core/starship.nix
   - Shell prompt configuration with Nerd Font symbols
   - Status: REPAIRED ✓ (removed invalid presets option)
   
2. home/gig/common/core/wezterm.nix  
   - Terminal emulator configuration with MonoLisa fonts
   - Status: CONFIGURATION VALID ✓
   
3. hosts/common/core/samba.nix
   - CIFS mount definitions for network shares (risa, vulcan, utility, etc.)
   - Status: CONFIGURATION VALID ✓

TECHNICAL ERROR ANALYSIS:
================================================================================

PRIMARY ERROR MESSAGE:
"flake does not provide attribute 'packages.x86_64-linux.homeConfigurations.\"merlin\".activationPackage'"

SECONDARY ERROR MESSAGE (revealed after primary fix):
"The option `programs.starship.presets' does not exist"

FLAKE STRUCTURE INVESTIGATION:
• Available home configurations:
  - "gig@wsl"       → WSL environment
  - "gig@spacedock" → Spacedock configuration  
  - "gig@merlin"    → MERLIN CONFIGURATION (CORRECT TARGET)
  - "gig@ganoslal"  → GanosLal configuration

CONFIGURATION REPAIR EXECUTED:
================================================================================

STARSHIP.NIX CORRECTIONS:
• REMOVED: Invalid 'presets' option from starship configuration
• RETAINED: All valid options (enable, enableZshIntegration, enableNushellIntegration)
• VALID CONFIG: Now properly uses only supported home-manager starship options

BEFORE (INVALID):
```nix
programs.starship = {
  enable = true;
  enableZshIntegration = true;
  presets = [                    # ← INVALID OPTION
    "nerd-font-symbols"
    "bracketed-segments"
  ];
  enableNushellIntegration = true;
  settings = { ... };
};
```

AFTER (CORRECTED):
```nix
programs.starship = {
  enable = true;
  enableZshIntegration = true;
  enableNushellIntegration = true;  # ← Valid configuration
  settings = { ... };               # ← Presets can be configured here if needed
};
```

FLEET HOME-MANAGER COMMAND REFERENCE:
================================================================================

CORRECT REBUILD COMMANDS BY VESSEL:
• merlin:    home-manager switch --flake .#gig@merlin
• wsl:       home-manager switch --flake .#gig@wsl  
• spacedock: home-manager switch --flake .#gig@spacedock
• ganoslal:  home-manager switch --flake .#gig@ganoslal

FLEET SCRIPTS VERIFICATION:
• scripts/home-manager-flake-rebuild.sh [HOST] → Should handle this correctly
• Manual commands require full "gig@hostname" format

TROUBLESHOOTING RECOMMENDATIONS:
================================================================================

IMMEDIATE RESOLUTION:
1. ✓ CORRECTED: Flake target specification (gig@merlin not merlin)
2. ✓ REPAIRED: Starship configuration syntax (removed invalid presets option)  
3. ✓ VERIFIED: Dry-run passes with both corrections applied

PREVENTIVE MEASURES:
1. UPDATE FLEET DOCUMENTATION: Ensure all engineers know correct flake targets
2. SCRIPT VERIFICATION: Confirm rebuild scripts use proper host detection
3. ERROR HANDLING: Add target validation to rebuild scripts
4. CONFIGURATION VALIDATION: Add home-manager option verification to procedures

FLEET OPERATIONAL INTELLIGENCE:
• Configuration files are NOW VALID after starship repair ✓
• Flake check passes for all NixOS and home configurations  
• Dry-run successful with corrected flake target and configuration
• Previous generation 53 remains intact and bootable

SYSTEM INTEGRITY STATUS:
• Current Generation: 58 (NixOS) operational
• Home Generation: 53 (intact, ready for successful rebuild)
• Git Tree: Modified (starship.nix repaired)
• Flake Lock: Current hash d43233f9... valid

ENGINEERING RECOMMENDATIONS:
================================================================================

HIGH PRIORITY:
• Document correct flake targets in fleet operations manual
• Implement actual rebuild with corrected command and configuration
• Verify fleet script compatibility with target naming

MAINTENANCE NOTES:
• All configuration changes are now valid and ready for deployment
• No rollback required - previous generation unaffected
• Starship configuration repair committed for future reference

TECHNICAL METADATA:
• Build Duration: 1 second (primary failure - evaluation only)
• Error Types: flake-attribute-not-found + invalid-home-manager-option
• Impact Scope: Single vessel (merlin home configuration)
• Recovery Complexity: SIMPLE - command syntax + configuration option fixes

HOME-MANAGER STARSHIP DOCUMENTATION REFERENCE:
• Available options: enable, enableZshIntegration, enableNushellIntegration, settings
• Presets configuration: Must be done via 'settings' attribute, not dedicated 'presets' option
• Configuration path: Uses settings.format and other starship TOML options

================================================================================
                                     Montgomery Scott, Chief Engineer
================================================================================

LESSONS LEARNED:
The failure cascade phenomenon - wrong flake target masked the configuration error.
Once we attempted correct target, the starship option error was revealed.
This demonstrates importance of methodical, layered debugging approach.

When home-manager option evaluation fails, always verify:
1. Correct flake target usage (user@host format)
2. Valid option names per home-manager module documentation  
3. Proper nix syntax and attribute structure

"Aye, that's the way with complex systems, Captain - fix one problem 
and it reveals the next. But now she should purr like a kitten!"

DRY-RUN VERIFICATION: ✓ PASSED - Configuration ready for actual deployment

================================================================================
