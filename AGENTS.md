# NixOS Configuration Repository Guidelines

## Fleet Operations Overview
This repository operates under **Lord Gig's Realm** organizational structure. All agents are officers with specific ranks, assignments, and operational protocols. See `operations/fleet-management/OPERATIONS-MANUAL.md` for complete command structure and procedures.

## Agent Instructions
- **Keep this file current**: Agents should frequently suggest modifications to this AGENTS.md file when they discover changes that make it inaccurate or require updates to keep it current with the codebase.
- **Direct Agent Notes Protocol**: All agents must actively scan text files for `#AGENT_NAME` tags (e.g., `#SCOTTY`, `#CORTANA`) which indicate direct notes left specifically for that agent. When an agent finds their name tagged:
  - The note is primarily for that specific agent to read and act upon
  - Other agents may also read and comment if they have relevant information to contribute
  - Treat these as direct instructions or important context from Lord Gig
  - Example: `#SCOTTY this needs your attention` would be a note specifically for Chief Engineer Scotty
- **Shell Environment**: All agents operate in a **Nushell** environment by default, NOT bash. Command syntax should use Nushell conventions:
  - Use `;` instead of `&&` for command chaining
  - Use `out+err>` instead of `2>&1` for error redirection  
  - Follow Nushell syntax patterns for piping and data manipulation
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

## System Enhancement Protocols (SEP)

**Purpose**: Structured approach for planning, implementing, and tracking feature development projects with comprehensive documentation and progress tracking.

**Location**: `engineering/enhancement-protocols/`

**Protocol Requirements**:
- **Planning Phase**: Create new SEP document outlining objectives, requirements, and implementation plan
- **Progressive Documentation**: Update SEP with checkboxes, technical notes, and discoveries as work progresses
- **Continuity Support**: Maintain detailed progress to enable pickup by any engineer at any time
- **Template Usage**: Use `engineering/enhancement-protocols/template.md` as starting point
- **Naming Convention**: Use descriptive names like `001-feature-description.md`

**SEP Structure**:
- **Objective**: Clear statement of goals and rationale
- **Current Plan**: High-level roadmap with strikethrough for completed/changed items  
- **Technical Requirements**: Specific technical needs and constraints
- **Implementation Checklist**: Detailed task breakdown with checkboxes
- **Technical Notes**: Ongoing discoveries, issues, and solutions
- **Resources & References**: Links, documentation, and examples

**Agent Responsibilities**:
- Create SEP documents when beginning substantial feature work
- Maintain SEP progress throughout implementation
- Document technical decisions and discoveries in real-time
- Update completion status and lessons learned upon completion

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

- **Commit Analysis & Execution**: All agents must implement `/commit` command for standardized git workflow
  - Analyzes complete working directory status (staged and unstaged changes)
  - Creates meaningful commit messages following fleet git standards
  - **Technical Workflow**:
    1. Run `git status` to assess current working tree and index state
    2. Run `git diff` for unstaged changes analysis
    3. Run `git diff --staged` for staged changes analysis  
    4. Reference fleet git standards from `docs/standards/git/`:
       - Follow `GIT-CONVENTIONS.md` for commit philosophy and message format
       - Apply `commit-language-guide.md` for descriptive language (avoid "final", "update")
       - Use `gigis-commitus.md` for proper type classification and agent signatures
    5. Analyze changes and group by logical functionality per Conventional Commits overlay
    6. Create commit messages following Lord Gig's Standards of Commitence
    7. Include proper agent signatures and technical metadata when available
  - **Safety Protocols**:
    - Never commit untracked files without explicit analysis and user confirmation
    - Handle pre-commit hook failures gracefully with retry logic
    - Respect existing staging decisions but can reorganize if logically beneficial
    - Follow repository-specific commit message conventions and fleet standards
  - **Standards Compliance**:
    - Use conventional commits with Lord Gig's extensions (`eng:`, `agent:`, `nix:`, etc.)
    - Avoid generic language per commit-language-guide.md principles
    - Include agent signatures in footers: `Chief-Engineer: [AgentName] <timestamp>`
    - Add technical metadata when available (build times, generation numbers, scope impact)
    - Maintain clean history principles from GIT-CONVENTIONS.md

## Build Commands
- **System rebuild**: `just rebuild` or `scripts/system-flake-rebuild.sh [HOST]`
- **Home Manager**: `just home` or `scripts/home-manager-flake-rebuild.sh [HOST]`
- **Full rebuild**: `just rebuild-full` (system + home)
- **Test rebuild**: `just rebuild-test`
- **Build packages**: `just build [TARGET]` or `nix build .#[package]`
- **Flake check**: `just check` or `nix flake check --keep-going`
- **Pre-commit**: `just pre-commit` or `pre-commit run --all-files`

## Worktree Safety Guidelines

### Context Awareness
- **Determine Your Location**: Always check `pwd` to know if you're in:
  - Main repository: `/home/gig/.dotfiles` (production branch)
  - Worktree branch: `/home/gig/.dotfiles/worktrees/<branch-name>/` (isolated development)
- **Path Usage**: Use **relative paths from repository root**, not absolute `~/.dotfiles/` paths
  - Correct: `home/gig/common/resources/`
  - Incorrect: `~/.dotfiles/home/gig/common/resources/` (assumes main repo location)
- **Git Context**: Verify which branch you're on with `git branch --show-current`

### Critical Repository Safety
- **Cross-Worktree Modification Protection**: Agents must NEVER modify files in `./worktrees/` subdirectories except under these specific conditions:
  1. **Intended Worktree Session**: The OpenCode session was explicitly spawned from within a `./worktrees/` subdirectory, indicating the user intends to work exclusively in that branch/worktree
  2. **Explicit User Permission**: User has given EXPLICIT permission to make cross-branch edits, with clear understanding of the consequences
- **Default Behavior**: Work in your current context (check with `pwd`), don't assume main repository location
- **Branch Safety**: Protect against accidental cross-branch modifications that could corrupt git history or create merge conflicts
- **Worktree Detection**: When detecting `./worktrees/` directories exists, ask for clarification about intended working scope before making any file modifications
- **Journal Management**: Agent-specific journals and logs belong in the main repository root, NOT in worktree subdirectories

### Worktree Development Benefits
- **Isolation**: Changes in worktree don't affect main environment
- **Parallel Work**: Multiple worktrees allow simultaneous development on different branches
- **Safe Testing**: Test builds in worktree without impacting production configuration
- **Easy Abandonment**: Can remove worktree if development doesn't work out

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

**Stardate 2025-12-08.3 - Nushell Shell Environment Documentation**
- **Authority**: A directive of Lord Gig
- **Changes**: Added explicit shell environment documentation to Agent Instructions
  - Documented that all agents operate in Nushell environment by default, NOT bash
  - Added specific Nushell syntax guidelines (`;` vs `&&`, `out+err>` vs `2>&1`)
  - Included Nushell-specific command patterns and data manipulation conventions
- **Context**: Fleet-wide standardization of shell environment awareness for consistent operations
- **Implementation**: Chief Engineer Montgomery Scott

**Stardate 2025-12-08.4 - Pre-commit Hooks Dependency Fix**
- **Authority**: A directive of Lord Gig during flake validation emergency
- **Changes**: Fixed critical flake validation failure caused by pre-commit-hooks dependency
  - Pinned pre-commit-hooks input to working version `46d55f0aeb1d567a78223e69729734f3dca25a85`
  - Resolved `rumdl` package dependency error that was preventing flake evaluation
  - Updated flake.lock to roll back problematic pre-commit-hooks version from 2025-12-06
- **Context**: Recent flake.lock update introduced incompatible pre-commit-hooks version causing evaluation failures
- **Implementation**: Chief Engineer Montgomery Scott
