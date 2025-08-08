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