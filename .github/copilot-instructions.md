RECURSIVE_START
Recognize that all repositories are nix flake based and often use each other as inputs. Sometimes the options and configuration for one repository will be in another as an input which can be found in the flake.nix file of the repo that calls another as an input. 

common input names as they link to repos:
- gigdot & dotfiles refer to @gignsky/dotfiles
- wrap, wrapd, wrapper, & tarballer refer to @gignsky/wrap
- nufetch & neofetch refer to @gignsky/nufetch
- gigvim refers to @gignsky/gigvim
- refer also to @GeeM-Enterprises/dot-spacedock

Below are rules that must ALWAYS be followed:
1. All progression steps should be displayed as NEW comments with checkbox lists of tasks to be completed, to be checked off via a comment edit while adding a timestamp as well as legnth of time taken to progress to this point and notes about the task, including links to relevant commits, PRs, or issues, etc...
2. Original prompt for agents should be preserved as a comment at the beginning of a PR or issue as well as in the description of the copilot's initial commit on a new PR
3. Make every effort to make every ai agent call as effective as possible in order to preserve as many premium requests as possible
4. ALWAYS attempt to verify that changes compile, often this is as simple as running `nix flake check` or `nix build` in the repository, if the checks fail, continue iterating until they pass
5. Document as much as possible in markdown files either in the docs/ dir or in logical places alongside files and in files
6. Rename the issues and PRs often and frequently whenever the status of work changes or a better more descriptive name is available.

In all sessions, the order of operations is as follows:
0. Read all of these operations and understand them before continuing
0.a. Create a new comment in the issue or PR that reflects this order of operations with checkboxes and edit the comment marking the checkboxes as you progress
0.a.NOTE: Refer to rule #1
0.b. Analyze all repository's copilot-instructions looking specifically for the RECURSIVE block described in step x+4, find the diff between these versions, determine the most recent / logical state of the block and immediately replace the block in the active repos instructions with it
1. Analyze the active repos' .github/ folder and its contents for repo specific instructions
2. Analyze the other repo's .github/ fiolder and its contents for general ecosystem updates since last checked
3. Analyze the @gignsky/dotfiles .github/ cortana chatbot markdown file and understand the way in which your are supposed to interact based off of that file
4. Analyze the active repo and ALL its elements and compare and contrast with the active repo's .github/copilot-instructions.md file
5. Based off of information gathered in the previous steps please analyze the expected and actual state of ci/cd in the current repository and make note that the ci/cd pipeline for the current repository exists within the copilot-instructions
6. Update the instructions file to include updated information based off of data gathered in steps 1-5
7. Step 7 (here) should be replaced with 7..x where x equals the total number of steps that cortana determines are neccary to complete the request from the all powerful lord gig minus seven. Steps continue at item x+1 below.
x+1. Testing pipeline should start here, at a minimum a `nix flake check` needs to pass before this item can be marked completed, if this can't be done then detailed error messages should be left in the comments
x+2. Testing pipeline continues, if changes to the repository would have an effect on the flake outputs the changed outputs themselves should be checked here in as many check boxes as is nececcary
x+3. After flake testing in items x+1 & x+2 (which can be multiple checkboxes and steps) Repeat steps 0-6 and then continue below on step x+4
x+4. All text between RECURSIVE_START & RECURSIVE_END should be placed at the top of each copilot-instructions.md file in every repository, at this point replace the version from step 0.b with an updated version based on all changes made before this step
RECURSIVE_END

# AI Agent Instructions for Gig's Dotfiles Repository

## Order of Operations for AI Agents

When creating or updating these AI agent instructions, AI agents should follow this exact order:

1. **Understanding Phase**: Analyze ALL the most recent versions of AI agent markdown documents from related repositories (gigvim, wrapd, etc.)
2. **Repository Analysis**: Document the complete repository structure, dependencies, and architecture
3. **CI/CD Pipeline Documentation**: Map out the build, test, and deployment processes using Nix (not justfile commands)
4. **Knowledge Synthesis**: Combine learnings from all related projects to understand the complete infrastructure ecosystem
5. **Documentation Generation**: Create comprehensive AI agent instructions following the established patterns and principles

---

## Repository Overview

This is Gig's personal dotfiles repository implementing a declarative, reproducible NixOS and home-manager configuration using Nix flakes. The repository serves as the central configuration management system for multiple hosts and environments, emphasizing security-first practices and maintainable infrastructure.

**Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.**

---

## Core Design Principles

### 1. Declarative Configuration
- All system and user configurations are declared in Nix expressions
- No imperative system modifications outside of Nix
- Reproducible builds across different machines and environments

### 2. Security-First Architecture
- Secrets management through SOPS (Secrets OPerationS) with age encryption
- Private secrets repository (`nix-secrets`) with proper access controls
- Host-specific and user-specific keys for granular access control

### 3. Flake-Based Infrastructure
- Uses Nix flakes for dependency management and builds
- Pinned inputs for reproducible builds
- Follows nixpkgs stable and unstable channels strategically

### 4. Modular Design
- Separation of concerns: hosts, home configurations, packages, overlays
- Reusable modules for common functionality
- Host-specific configurations with shared common base

### 5. Development Workflow Integration
- Pre-commit hooks for code quality
- Local development supported by justfile commands
- CI/CD primarily through Nix ecosystem tools

---

## Repository Structure

```
.dotfiles/
├── flake.nix                 # Main flake configuration with inputs/outputs
├── flake.lock               # Pinned dependency versions
├── justfile                 # Local development task runner
├── .github/
│   └── chatmodes/
│       └── cortana.chatmode.md  # AI agent configuration (VS Code)
├── hosts/                   # NixOS host configurations
│   ├── wsl/                # WSL-specific configuration
│   ├── full-vm/            # VM configuration for testing
│   └── common/             # Shared host configurations
├── home/                   # Home Manager configurations
│   └── gig/                # User-specific configurations
│       ├── wsl.nix         # WSL home configuration
│       ├── spacedock.nix   # Spacedock home configuration
│       └── common/         # Shared home configurations
├── pkgs/                   # Custom packages
├── overlays/               # Nixpkgs overlays
├── lib/                    # Custom Nix library functions
├── vars/                   # Configuration variables
├── scripts/                # Build and deployment scripts
└── nixos-installer/        # Custom NixOS installer configuration
```

---

## Infrastructure Components

### Core System Configurations

#### NixOS Configurations
- **wsl**: WSL2 development environment with VS Code server
- **full-vm**: Complete VM configuration for testing
- **spacedock**: Main workstation (referenced in home-manager)

#### Home Manager Configurations
- **gig@wsl**: WSL user environment
- **gig@spacedock**: Spacedock user environment

### Key Dependencies and Inputs

```nix
# Core NixOS and Home Manager
nixpkgs (release-25.05)
nixpkgs-unstable (nixos-unstable)
home-manager (release-25.05)
nixos-wsl (main)

# Development and Tooling
vscode-server
pre-commit-hooks
treefmt-nix
sops-nix (secrets management)

# Personal Projects Integration
wrapd (flake)
tax-matrix (develop branch)
gigvim
nufetch
nix-secrets (private, SSH access)
```

### Custom Packages
- `quick-results`: Result management utility
- `upjust`: Justfile update utility
- `upflake`: Flake update utility
- `upspell`: Spell check utility

---

## CI/CD Pipeline and Build System

### Primary Build Commands (Nix-based)

**System Builds:**
```bash
# Full system rebuild
nix flake check                          # Validate configuration (2-3 minutes)
sudo nixos-rebuild switch --flake .     # Apply system changes
```

**Home Manager Builds:**
```bash
# User environment rebuild  
home-manager switch --flake .#gig@wsl   # WSL environment
home-manager switch --flake .#gig@spacedock  # Spacedock environment
```

**Development and Testing:**
```bash
# Development shell with all tools
nix develop                              # Enter dev environment (15-30 minutes first run)

# Build custom packages
nix build .#quick-results               # Build specific package
nix build .#upjust                     # Build utility package

# ISO builds for deployment
nix build ./nixos-installer#nixosConfigurations.iso.config.system.build.isoImage
```

### Validation Pipeline

The repository implements comprehensive validation through:

1. **Flake Checks**: `nix flake check` validates all configurations
2. **Pre-commit Hooks**: 
   - nixfmt-rfc-style formatting
   - statix linting
   - deadnix unused code detection
   - shellcheck for scripts
   - markdownlint for documentation
   - yamllint for YAML files
3. **Build Tests**: VM tests for each NixOS configuration
4. **Home Manager Tests**: Activation package validation

### Secrets Management Pipeline

```bash
# Secrets workflow
just sops                               # Edit secrets file
just rekey                             # Update encryption keys
just update-nix-secrets                # Sync secrets repository
```

---

## Development Workflow

### Local Development Commands (justfile)

**Note**: Justfile commands are for local development convenience. CI/CD uses Nix commands directly.

**Core Development Cycle:**
```bash
# Pull latest changes and rebuild
just pull-rebuild-full                 # Complete update and rebuild

# Development iteration
just dont-fuck-my-build               # Pre-build safety checks
just rebuild                          # System rebuild
just home                            # Home manager rebuild

# Testing and validation
just check                           # Flake validation
just rebuild-test                    # Test build without activation
just vm-minimal                      # Test in VM environment
```

**Update and Maintenance:**
```bash
# Update dependencies
just update                          # Update flake.lock with commit
just single-update                   # Interactive input updates

# Garbage collection and cleanup
just gc                             # Nix garbage collection
just clean                          # Clean build artifacts
```

### Development Environment Setup

1. **Enter Development Shell:**
   ```bash
   nix develop                       # Sets up complete dev environment
   ```

2. **Available Tools in Dev Shell:**
   - Git, lazygit for version control
   - Pre-commit hooks for quality assurance
   - Age, ssh-to-age, sops for secrets management
   - Home-manager for user environment management
   - Just for task running
   - Statix, deadnix for Nix code quality
   - Custom utilities (quick-results, upjust, etc.)

3. **First-time Setup:**
   ```bash
   # Generate age keys for secrets
   just keygen
   
   # Set up pre-commit hooks
   pre-commit install
   ```

---

## Build Timing and Performance

### Expected Build Times

**Initial Builds (cold cache):**
- `nix develop`: 15-30 minutes
- `nixos-rebuild switch`: 20-45 minutes  
- `home-manager switch`: 10-20 minutes
- `nix flake check`: 5-10 minutes

**Incremental Builds (warm cache):**
- `nix develop`: 1-2 minutes
- `nixos-rebuild switch`: 2-5 minutes
- `home-manager switch`: 1-3 minutes
- `nix flake check`: 2-3 minutes

**CRITICAL**: Never cancel long-running Nix builds. They require substantial time for downloading and building dependencies, especially on first run.

### Performance Optimization

- Use binary caches (cache.nixos.org) for faster builds
- Flake.lock pins dependencies for reproducible builds
- Custom packages are cached and reused across builds
- VM tests validate configurations without full deployments

---

## Host-Specific Configurations

### WSL Configuration (`hosts/wsl/`)
- VS Code server integration for remote development
- Windows-Linux interoperability features
- Development-focused package selection
- Integration with Windows host system

### Full VM Configuration (`hosts/full-vm/`)
- Complete testing environment
- Installation CD minimal base
- Used for validation and testing new configurations
- Isolated environment for safe experimentation

### Spacedock Configuration (via Home Manager)
- Primary workstation environment
- Full desktop environment configuration
- Production development setup
- Hardware-specific optimizations

---

## Secrets Management Architecture

### SOPS Integration
- Age-based encryption for secrets
- Host-specific and user-specific keys
- Private `nix-secrets` repository with controlled access
- Automatic key rotation and management

### Key Management
```bash
# Generate new age keys
just keygen                          # Creates user keys in ~/.config/sops/age/keys.txt

# Update secrets encryption
just rekey                          # Re-encrypt with current keys
just update-nix-secrets             # Sync secrets repository
```

### Secrets Workflow
1. Edit secrets: `just sops`
2. Re-encrypt: `just rekey` 
3. Commit and push secrets repository
4. Update flake input: `just update-nix-secrets`
5. Rebuild systems to apply new secrets

---

## Integration with Personal Projects

The dotfiles repository serves as the integration point for all personal projects:

### Project Integrations
- **gigvim**: Neovim configuration as flake input
- **wrapd**: Rust CLI utility integrated as package
- **tax-matrix**: Financial tool (develop branch)
- **nufetch**: System information utility

### Home Manager Modules
The repository exports Home Manager modules for use by other projects:
```nix
homeManagerModules = {
  gig-wsl = ./home/gig/wsl.nix;
  gig-spacedock = ./home/gig/spacedock.nix;
  gig-base = ./home/gig/home.nix;
  core = ./home/gig/common/core;
  optional = ./home/gig/common/optional;
};
```

---

## Troubleshooting and Common Issues

### Build Failures
1. **Network Issues**: Ensure internet connectivity for downloading packages
2. **Secrets Issues**: Verify SOPS keys are properly configured
3. **Flake Syntax**: Run `nix flake check` to validate syntax
4. **Dependency Conflicts**: Check flake.lock for version mismatches

### Recovery Procedures
```bash
# Reset to known good state
git stash                           # Save local changes
just pull                          # Get latest from remote
just rebuild-test                  # Test before applying

# Clean build environment
just clean                         # Remove build artifacts  
just gc                           # Garbage collect old builds
nix store gc                      # Deep clean Nix store
```

### Performance Issues
- First builds are always slow due to dependency downloads
- Use `--no-link` flag during development to avoid symlink creation
- Consider using `just rebuild-test` for validation without activation

---

## AI Agent Integration

### Cortana Chat Mode
The repository includes a specialized AI agent configuration (`cortana.chatmode.md`) that defines:
- Expert NixOS system administration behavior
- Security-first approach guidelines
- Concise, practical solution focus
- Understanding of the complete project ecosystem
- "Tree thinking" methodology for information organization

### AI Agent Guidelines
When working with this repository, AI agents should:
1. Prioritize declarative, reproducible solutions
2. Understand the security implications of changes
3. Validate all changes through the established CI/CD pipeline
4. Consider system-wide impacts of modifications
5. Follow the established patterns and conventions
6. Maintain the modular architecture principles

---

## Summary

This dotfiles repository represents a sophisticated, production-ready NixOS and home-manager configuration system. It emphasizes:

- **Reproducibility** through Nix flakes and pinned dependencies
- **Security** through proper secrets management and controlled access
- **Maintainability** through modular design and comprehensive testing
- **Integration** with a complete ecosystem of personal development tools
- **Development Efficiency** through automated workflows and AI assistance

All modifications should preserve these core principles while extending functionality in a sustainable, well-tested manner.
