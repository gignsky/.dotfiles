# Roll Flow: Git Workflow for NixOS Multi-Host Configurations

**Version 1.0 - Stardate 2026-05-30**  
**Chief Engineer: Montgomery Scott**

## What is Roll Flow?

Roll Flow is a git workflow management system specifically designed for NixOS dotfiles across multiple hosts. Unlike git-flow (designed for versioned software releases), Roll Flow handles **continuous rolling releases** similar to NixOS unstable, but with stability checkpoints.

## The Problem It Solves

When managing NixOS configurations for multiple machines (ganoslal, merlin, wsl), you often face these challenges:

1. **Changes work on one host but break another** (different hardware, different use cases)
2. **Need to iterate quickly** on one system without affecting others
3. **Want a stable fallback** when experiments go wrong
4. **Hard to track** what's tested vs. untested across hosts

Roll Flow solves this by providing **progressive stability gates**:
- Work freely in feature branches
- Batch related changes into numbered "rolls"
- Graduate rolls to a rolling integration branch when they work on some hosts
- Promote to main only when verified on ALL hosts

## Quick Start

### 1. Initialize (one-time setup)

```bash
just roll-init
```

### 2. Start your first roll

```bash
just roll-start shell-improvements
```

### 3. Create and integrate features

```bash
git checkout -b feature/zellij-config
# ... make changes ...
just rebuild  # Test it

just roll-integrate feature/zellij-config
```

### 4. Graduate when ready

```bash
just roll-graduate  # Moves to rolling branch
```

### 5. Test on other hosts, then promote

```bash
# After testing on all hosts...
just roll-promote  # Moves to main and tags it
```

## Documentation Structure

This workflow includes comprehensive documentation:

1. **[ROLL-FLOW-WORKFLOW.md](./ROLL-FLOW-WORKFLOW.md)** - Complete guide with examples and best practices
2. **[ROLL-FLOW-QUICKREF.md](./ROLL-FLOW-QUICKREF.md)** - Quick reference card for common commands
3. **[ROLL-FLOW-DIAGRAMS.md](./ROLL-FLOW-DIAGRAMS.md)** - Visual diagrams and flowcharts
4. **[ROLL-FLOW-MIGRATION.md](./ROLL-FLOW-MIGRATION.md)** - Guide for converting existing branches

## Key Commands

| Command | Purpose |
|---------|---------|
| `just roll-init` | Initialize roll-flow (one-time) |
| `just roll-start <theme>` | Begin new numbered roll |
| `just roll-integrate <branch>` | Add feature to current roll |
| `just roll-graduate` | Move roll → rolling |
| `just roll-promote` | Move rolling → main |
| `just roll-status` | Check current state |
| `just roll-list` | List all rolls |
| `just roll-test-all` | Build for all hosts |

## Branch Structure

```
feature branches → roll/N-MMDD-theme → rolling → main
                   (themed batches)    (tested)  (verified all)
```

### Branch Purposes

- **`main`**: Verified stable for ALL hosts (ganoslal, merlin, wsl)
- **`rolling`**: Integration branch, like nixos-unstable
- **`roll/N-*`**: Numbered batches of themed changes
- **`feature/*`**: Individual features or fixes

## Example Roll Names

```
roll/4-0530-shell-improvements
roll/5-0601-display-config
roll/6-0602-nixos-26.05-migration
```

Format: `roll/<number>-<MMDD>-<descriptive-theme>`

## When to Use Each Command

### Start a new roll when:
- ✅ Beginning themed work (shell config, displays, monitoring)
- ✅ After graduating previous roll
- ✅ Switching focus areas

### Graduate to rolling when:
- ✅ Builds successfully on target host
- ✅ Basic testing complete
- ❌ Doesn't need to work on all hosts yet

### Promote to main when:
- ✅ Tested on ganoslal
- ✅ Tested on merlin
- ✅ Tested on wsl
- ✅ No known issues anywhere

## Philosophy

### Unlike Git-Flow

| Git-Flow | Roll Flow |
|----------|-----------|
| `develop` branch | `rolling` branch |
| `release/*` branches | Not needed (Nix generations handle this) |
| `hotfix/*` branches | Just fix in rolling, fast-forward if urgent |
| Version tags | Date tags on main for milestones |
| Release process | Continuous promotion when stable |

### Why "Rolls"?

The name comes from **rolling releases** (like NixOS unstable) combined with **numbered rollup batches**. Each roll "rolls up" related changes into a cohesive unit that can be tested and graduated together.

## Advantages

1. **Safe experimentation**: Work in rolls without affecting stable main
2. **Progressive stability**: Graduates from feature → roll → rolling → main
3. **Multi-host aware**: Built-in testing across all configured hosts
4. **Easy rollback**: Both git-level (branches) and Nix-level (generations)
5. **Clear history**: Numbered rolls make it easy to track what happened when
6. **No version overhead**: No release numbers, semantic versioning, etc.

## Integration with Fleet Operations

Roll Flow integrates with Lord Gig's Fleet Operations protocols:

- **Git Standards**: All commits follow fleet git conventions
- **Quest Reports**: Major rolls should have corresponding quest reports
- **Engineering Logs**: Use `.tmp-oc-logs/` during development, archive to annex when complete
- **Commit Protocol**: Follow Lord Gig's Standards of Commitence

See [operations/fleet-management/OPERATIONS-MANUAL.md](../../operations/fleet-management/OPERATIONS-MANUAL.md) for details.

## Tool Location

The `roll-flow` command-line tool is:

**Source**: `~/.dotfiles/scripts/roll-flow` (Nushell script)  
**Package**: Available via `nix run .#roll-flow` or through just recipes  
**Just Recipes**: Integrated in justfile for easy access

The tool is packaged as a Nix derivation with proper dependency injection (nushell, git, nix), ensuring it works consistently across all hosts.

## Configuration

Roll flow stores configuration in:

```
~/.config/roll-flow/config.nuon
~/.config/roll-flow/rolls/<N>.nuon  (metadata for each roll)
```

Configuration includes:
- Repository root path
- Branch names (rolling, main)
- Host list for testing
- Roll prefix and numbering

## Next Steps

### For New Users

1. Read [ROLL-FLOW-WORKFLOW.md](./ROLL-FLOW-WORKFLOW.md) for complete workflow guide
2. Study [ROLL-FLOW-DIAGRAMS.md](./ROLL-FLOW-DIAGRAMS.md) for visual understanding
3. Keep [ROLL-FLOW-QUICKREF.md](./ROLL-FLOW-QUICKREF.md) handy as a cheat sheet

### For Existing dotfiles repo

1. Follow [ROLL-FLOW-MIGRATION.md](./ROLL-FLOW-MIGRATION.md) to convert existing branches
2. Choose between clean migration (fast) or gradual migration (safe)
3. Test the workflow with a small roll before committing fully

## Support & Contribution

This workflow was designed by Chief Engineer Montgomery Scott for Lord Gig's Realm fleet operations. 

**Questions or Issues?**
- Check the documentation files listed above
- Review examples in the workflow guide
- Consult fleet operations protocols

**Improvements?**
- Follow fleet protocols for suggesting changes to agent systems
- Test modifications on a branch first
- Document changes in AGENTS.md changelog

---

*"A good git workflow is like a well-maintained warp core - it keeps everything runnin' smooth, prevents catastrophic failures, and makes it easy to back out of experimental modifications!"*

— Chief Engineer Montgomery Scott  
Stardate 2026-05-30

---

## Quick Reference Card

```
┌────────────────────────────────────────────────────────────┐
│                  ROLL FLOW QUICK START                     │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  Initialize:      just roll-init                          │
│  Start roll:      just roll-start <theme>                 │
│  Integrate:       just roll-integrate <branch>            │
│  Graduate:        just roll-graduate                       │
│  Promote:         just roll-promote                        │
│  Check status:    just roll-status                         │
│                                                            │
│  Flow:  feature → roll/N → rolling → main                 │
│         (work)    (batch)  (tested)  (stable all)         │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

## File Checklist

- [x] `scripts/roll-flow` - Main workflow tool (Nushell script)
- [x] `docs/guides/ROLL-FLOW-README.md` - This file
- [x] `docs/guides/ROLL-FLOW-WORKFLOW.md` - Complete guide
- [x] `docs/guides/ROLL-FLOW-QUICKREF.md` - Quick reference
- [x] `docs/guides/ROLL-FLOW-DIAGRAMS.md` - Visual diagrams
- [x] `docs/guides/ROLL-FLOW-MIGRATION.md` - Migration guide
- [x] `justfile` - Integrated just recipes (roll-* commands)
- [x] `AGENTS.md` - Updated with Roll Flow section
