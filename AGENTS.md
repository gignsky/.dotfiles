# NixOS Configuration Repository Guidelines

## Agent Instructions
- **Keep this file current**: Agents should frequently suggest modifications to this AGENTS.md file when they discover changes that make it inaccurate or require updates to keep it current with the codebase.

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
