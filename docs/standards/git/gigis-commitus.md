# Lord Gig's Standards of Commitence
*An overlay and extension to the Conventional Commits specification*

## Base Standard
This repository follows [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) as the foundation, with the following core types:

### Standard Types
- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation only changes
- `style`: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)
- `refactor`: A code change that neither fixes a bug nor adds a feature
- `perf`: A code change that improves performance
- `test`: Adding missing tests or correcting existing tests
- `build`: Changes that affect the build system or external dependencies
- `ci`: Changes to CI configuration files and scripts
- `chore`: Other changes that don't modify src or test files
- `revert`: Reverts a previous commit

## Lord Gig's Extensions

### Engineering & Operations
- `eng`: Engineering infrastructure, tooling, and system improvements
- `ops`: Operational changes, deployment configurations, monitoring
- `security`: Security-related changes, vulnerability fixes, access controls
- `config`: Configuration file updates, environment variables, settings

### Agent & Automation
- `agent`: Agent-specific changes, AI assistant modifications, personality updates
- `auto`: Automated system changes, script generations, scheduled updates
- `hook`: Git hooks, pre-commit configurations, automated validations
- `log`: Logging system changes, audit trails, monitoring enhancements

### Fleet & Infrastructure  
- `fleet`: Multi-host or fleet-wide changes affecting multiple systems
- `nix`: Nix/NixOS specific changes, flake updates, package modifications
- `home`: Home Manager specific configurations, user environment changes
- `host`: Host-specific changes, hardware configurations, system-level mods

### Communication & Documentation
- `comm`: Communication protocols, APIs, inter-system messaging
- `sitrep`: Situation reports, status updates, fleet communications
- `metrics`: Performance metrics, analytics, measurement systems
- `journal`: Engineering journals, logs, historical documentation

## Commit Message Structure

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Enhanced Description Guidelines
When technical data is available, descriptions should include:
- **Build/Generation info**: "feat: add dark mode toggle (gen 42→43, 15s build)"
- **System scope**: "fix(spacedock): resolve GPU driver conflict"  
- **Impact scope**: "refactor: optimize flake structure (affects 4 hosts)"
- **State changes**: "config: update SSH keys (3 hosts, clean tree)"

### Agent Signatures
All commits should include appropriate attribution in footers:
- **Scotty**: `Chief-Engineer: Scotty <2025.12.03-14:30>`
- **Captain/User**: `Captain: Lord-Gig <2025.12.03-14:30>`
- **Auto Systems**: `Auto-System: <script-name> <2025.12.03-14:30>`
- **Collaborative**: `Co-authored-by: Agent-Name <role> <timestamp>`

### Examples

```
feat(opencode): add commit enhancement system

Implement automated commit message enrichment with technical details:
- Custom conventional commit overlay (gigis-commitus.md)  
- Pre-merge hooks for automatic enhancement
- Agent signature system with timestamps
- /liven-commits command for manual processing

Affects: scripts/commit-enhance-lib.sh, .github/workflows/
Build: Clean tree, generation 44→44, 8s validation

Chief-Engineer: Scotty <2025.12.03-14:45>
```

```
auto(metrics): record spacedock build performance

Generation 42→42 rebuild completed successfully in 27s
No configuration changes detected, routine maintenance cycle
Fleet status: All systems nominal

Auto-System: home-manager-flake-rebuild.sh <2025.12.02-19:41>
```

## Usage Guidelines

### When to Use Extensions
- Use standard types when changes fit conventional categories
- Use extensions for domain-specific work (Nix, agents, fleet ops)
- Prefer standard types for external/upstream compatibility
- Use extensions for internal engineering communications

### Scope Guidelines  
- Host-specific: `(spacedock)`, `(ganoslal)`, `(merlin)`
- Component-specific: `(bspwm)`, `(nushell)`, `(opencode)`
- System-wide: No scope or `(fleet)` for multi-host changes

### Future Extensions
This document is living and should be updated as new patterns emerge. Add new types as needed for repository-specific workflows, always maintaining compatibility with conventional commits base standard.

---
*Last updated: 2025.12.03 by Chief-Engineer: Scotty*
