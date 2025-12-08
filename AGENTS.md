# NixOS Configuration Repository Guidelines

## Fleet Operations Overview
This repository operates under **Lord Gig's Realm** organizational structure. All agents are officers with specific ranks, assignments, and operational protocols. See `operations/fleet-management/OPERATIONS-MANUAL.md` for complete command structure and procedures.

## Agent Instructions
- **Keep this file current**: Agents should frequently suggest modifications to this AGENTS.md file when they discover changes that make it inaccurate or require updates to keep it current with the codebase.
- **Fleet Protocols**: All agents must follow fleet command structure and quest documentation requirements
- **Critical Fleet Architecture**: All agents must reference `operations/fleet-management/OPERATIONS-MANUAL.md` for foundational knowledge including:
  - WSL hostname constraints and flake target mappings (`nixos` → `wsl`)
  - Physical host detection methods for logging differentiation
  - Rebuild command behavior and automatic host detection
  - Essential for proper operation in WSL environments

## Fleet Operations & Quest Protocols

### Expedition of Consultation Requirements
When consulting on repositories outside your primary assignment:

1. **Pre-Expedition Safety Check**
   - Verify no uncommitted changes in home repository (`git status`)
   - Ensure target repository branch is appropriate for work
   - **Optional Worktree Isolation**: Consider creating temporary worktree under `./worktrees/<agent-name>-expedition-<date>/` for additional safety
   - Document expedition objectives clearly

2. **Quest Documentation Standards**
   - **REQUIRED**: Create quest report in `operations/reports/away-reports/YYYY-MM-DD_[quest-type].md`
   - **Progressive Documentation**: Make frequent small notes throughout expedition - compile into final report at end
   - **"COMMIT SMALL & COMMIT OFTEN"**: Document progress incrementally to preserve detail and progression
   - Include: technical findings, solutions implemented, repository status, recommendations
   - For multi-officer expeditions: senior officer files formal report, others provide supporting accounts
   - **Safe Commit Protocol**: Never accidentally commit incomplete work from target repository

3. **Post-Expedition Procedures**
   - Compile progressive notes into comprehensive final quest report
   - Commit quest reports to home repository (NOT target repository)
   - Update fleet assignment registry if needed
   - Report completion status to command structure
   - Clean up temporary worktrees if used

### Repository Assignment System
- **Primary Assignment**: Officer's main repository and domain expertise (see `operations/fleet-management/OPERATIONS-MANUAL.md` for current assignments)
- **Expeditions of Consultation**: Temporary consultation work in other repositories
- **Cross-Domain Authority**: Senior officers may override normal assignment boundaries for critical operations

## Universal Agent Commands
- **Situation Reports**: All agents must implement `/sitrep` command for standardized status reporting
  - Provides comprehensive operational status in agent-specific voice
  - Includes current operations, system health, recent activities, and recommendations
  - Standard format with agent personality adaptations (see Scotty agent for reference implementation)
  - Essential for fleet-wide situational awareness and coordination

- **Log Integrity Repair**: All agents must implement `/fix-log` command for documentation maintenance
  - Analyzes current state of agent's domain/specialization area
  - Identifies gaps or missing information in existing logs
  - Documents findings in agent-specific log format and voice
  - **Enhanced Quality Assurance Protocol**:
    - Checks git working tree and index for any uncommitted changes
    - If non-log changes detected, runs `/check` (flake validation) before committing
    - Commits non-log changes first (if validation passes), then log updates separately
    - Uses descriptive commit messages for technical changes, standardized format for logs
    - Documents any validation failures in logs for future reference
  - Updates logs to accurately reflect current operational state
  - Commits all documentation changes immediately to repository
  - Essential for maintaining accurate historical records and operational continuity

## Build Commands
- **System rebuild**: `just rebuild` or `scripts/system-flake-rebuild.sh [HOST]`
- **Home Manager**: `just home` or `scripts/home-manager-flake-rebuild.sh [HOST]`
- **Full rebuild**: `just rebuild-full` (system + home)
- **Test rebuild**: `just rebuild-test`
- **Build packages**: `just build [TARGET]` or `nix build .#[package]`
- **Flake check**: `just check` or `nix flake check --keep-going`
- **Pre-commit**: `just pre-commit` or `pre-commit run --all-files`

## Worktree Safety Guidelines
- **Critical Repository Safety**: Agents must NEVER modify files in `./worktrees/` subdirectories except under these specific conditions:
  1. **Intended Worktree Session**: The OpenCode session was explicitly spawned from within a `./worktrees/` subdirectory, indicating the user intends to work exclusively in that branch/worktree
  2. **Explicit User Permission**: User has given EXPLICIT permission to make cross-branch edits, with clear understanding of the consequences
- **Default Behavior**: Always work in the main repository root (`/home/gig/.dotfiles`) unless specifically directed otherwise
- **Branch Safety**: Protect against accidental cross-branch modifications that could corrupt git history or create merge conflicts
- **Worktree Awareness**: When detecting `./worktrees/` directories, ask for clarification about intended working scope before making any file modifications
- **Journal Management**: Agent-specific journals and logs belong in the main repository root, NOT in worktree subdirectories

## Code Style Guidelines
- **File naming**: Use kebab-case for .nix files (e.g., `hardware-configuration.nix`)
- **Imports**: Use relative paths with `./` prefix for local imports
- **Formatting**: Run `nixfmt-rfc-style` via pre-commit hooks
- **Comments**: Use `#` for comments, avoid inline comments on imports
- **Function params**: Use destructuring `{ pkgs, lib, ... }:` pattern
- **Packages**: Define in `home.packages = with pkgs; [ ... ];` lists
- **String interpolation**: Use `"${variable}"` syntax
- **Attributes**: Use dot notation for nested attributes where possible
- **Line length**: Keep lines reasonable, break long attribute lists
- **Error handling**: Use `lib.mkDefault` for overridable defaults
- **Documentation**: Include brief comments for complex configurations

---

## Change Log & Context

**Stardate 2025-12-03.1 - Fleet Operations System Implementation**  
- **Authority**: A directive of Lord Gig during comprehensive AGENTS.md review
- **Changes**: Established Lord Gig's Realm fleet operations framework
  - Added Expedition of Consultation protocols with safety checks
  - Implemented Quest Reports system in `operations/reports/away-reports/`
  - Added progressive documentation requirements ("COMMIT SMALL & COMMIT OFTEN")
  - Established worktree isolation options for sensitive operations
- **Context**: Need for systematic cross-repository consultation while maintaining safety and documentation standards
- **Implementation**: Chief Engineer Montgomery Scott

**Stardate 2025-12-03.2 - File Structure and Reference Updates**
- **Authority**: A directive of Lord Gig 
- **Changes**: 
  - Renamed `FLEET-OPERATIONS-MANUAL.md` to `OPERATIONS-MANUAL.md` for clarity
  - Updated all references to point to new filename
- **Context**: Simplified naming convention, more direct and accessible
- **Implementation**: Chief Engineer Montgomery Scott

**Stardate 2025-12-08.1 - Repository Organization Modernization**
- **Authority**: A directive of Lord Gig  
- **Changes**: Implemented comprehensive repository reorganization
  - Created `docs/` structure: guides/, planning/, creative/, standards/
  - Established `operations/` hub: logs/, reports/, metrics/, fleet-management/
  - Added `archives/` for historical content preservation
  - Updated all file references to reflect new directory structure
  - Created comprehensive README.md files for each directory with filing guidelines
- **Context**: Systematic organization of scattered documentation, musings, and operational content
- **Implementation**: Chief Engineer Montgomery Scott

**Stardate 2025-12-03.3 - Authority Language Standardization**
- **Authority**: A directive of Lord Gig
- **Changes**: Corrected authority references to proper "A directive of Lord Gig" format throughout documentation
- **Context**: Maintains proper formality while acknowledging close working relationship 
- **Implementation**: Chief Engineer Montgomery Scott
