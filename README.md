# Lord Gig's Realm - NixOS Configuration Repository

Personal NixOS configuration repository with fleet operations and comprehensive documentation system.

## Repository Structure

### 📚 **docs/** - Documentation Hub
Organized documentation, guides, creative works, and reference materials:
- **guides/**: Technical documentation and tutorials
- **creative/**: Personal writing, musings, and artistic expressions
- **standards/**: Conventions, protocols, and coding standards
- **planning/**: Project planning and organized task materials

### ⚓ **operations/** - Fleet Operations
Operational activities, logs, and fleet management:
- **logs/**: Engineering and operational logs
- **reports/**: Mission reports and expedition documentation
- **metrics/**: Performance tracking and system monitoring
- **fleet-management/**: Organizational documents and procedures

### 🗂️ **archives/** - Historical Preservation
Legacy content and historical materials:
- **old-sessions/**: Historical interaction sessions
- **deprecated/**: Outdated but historically significant content
- **reference/**: Keep-for-reference materials

### 📝 **Active Working Documents**
- **notes.md**: Captain's operational log and primary working notes
- **AGENTS.md**: Agent instructions and fleet protocols

## Fleet Operations

This repository operates under **Lord Gig's Realm** organizational structure with specialized agent roles and comprehensive operational protocols. See `operations/fleet-management/OPERATIONS-MANUAL.md` for complete details.

## Build Commands

- **System rebuild**: `just rebuild` or `scripts/system-flake-rebuild.sh [HOST]`
- **Home Manager**: `just home` or `scripts/home-manager-flake-rebuild.sh [HOST]`
- **Full rebuild**: `just rebuild-full` (system + home)
- **Flake check**: `just check` or `nix flake check --keep-going`

## Hosts

Current fleet configuration supports multiple hosts:
- **ganoslal**: Primary workstation with dual-GPU setup
- **merlin**: Secondary system
- **mganos**: Additional host configuration
- **spacedock**: Fleet operational hub
- **wsl**: Windows Subsystem for Linux configuration

## Documentation Philosophy

This repository maintains comprehensive documentation through:
- **Progressive Documentation**: Regular logging and note-taking
- **Clear Organization**: Logical categorization of content types
- **Operational Continuity**: Detailed mission and engineering logs
- **Creative Expression**: Space for personal writing and musings

Documentation is a living system that evolves with the repository's growth and operational needs.
