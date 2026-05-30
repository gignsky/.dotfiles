# Roll Flow Workflow Guide

**Lord Gig's NixOS Configuration Management System**

## Overview

Roll Flow is a git workflow management system designed specifically for multi-host NixOS configurations. It provides a structured approach to managing changes across multiple systems while maintaining stability.

## Philosophy

Unlike git-flow which is designed for versioned software releases, Roll Flow is designed for **continuous rolling releases** similar to NixOS unstable, but with stability checkpoints.

### Key Concepts

- **`main`** - Verified stable state for ALL hosts
- **`rolling`** - Integration branch (like nixos-unstable)
- **`roll/N-*`** - Numbered batches of themed changes
- **Feature branches** - Individual features or fixes

## Branch Hierarchy

```
feature/zellij-config ─┐
feature/display-fix ───┼─→ roll/4-0530-shell-improvements ─→ rolling ─→ main
dev/wayland ───────────┘                                         ↑         ↑
                                                         (tested on      (tested on
                                                          some hosts)    ALL hosts)
```

## Workflow Commands

### Installation

```bash
# Initialize roll-flow in your repository
just roll-init
```

This creates `~/.config/roll-flow/config.nuon` with your repository settings.

### Starting a New Roll

```bash
# Start a new roll with a descriptive theme
just roll-start shell-improvements

# This creates: roll/N-MMDD-shell-improvements
# Where N is auto-incremented from existing rolls
```

**When to start a new roll:**
- Beginning a new themed batch of work (e.g., display configuration, shell improvements)
- After graduating the previous roll to `rolling`
- When working on a major feature that will take multiple sessions

### Working on Features

```bash
# Create feature branch from current roll
git checkout -b feature/zellij-config

# Make your changes...
# Test with: just rebuild

# When ready, integrate into current roll
just roll-integrate feature/zellij-config
```

### Graduating a Roll

```bash
# When roll is stable on at least one host
just roll-graduate

# This:
# 1. Merges current roll → rolling
# 2. Pushes to remote
# 3. Marks roll as "graduated" in metadata
# 4. Keeps roll branch for reference
```

**Graduation criteria:**
- ✅ Builds successfully on target host(s)
- ✅ No obvious runtime issues
- ⚠️  Doesn't need to work on ALL hosts yet

### Promoting to Main

```bash
# When rolling is verified on ALL hosts
just roll-promote

# This:
# 1. Confirms you've tested all hosts
# 2. Merges rolling → main
# 3. Creates dated tag (e.g., stable-20260530)
# 4. Pushes everything
```

**Promotion criteria:**
- ✅ Tested and working on **ganoslal**
- ✅ Tested and working on **merlin**
- ✅ Tested and working on **wsl**
- ✅ No known issues on any host

### Status and Monitoring

```bash
# Check current roll status
just roll-status

# List all rolls
just roll-list

# Test builds on all hosts (without deploying)
just roll-test-all
```

## Complete Example Workflow

### Scenario: Adding Zellij Configuration

```bash
# 1. Start a new roll for shell improvements
just roll-start shell-improvements
# Creates: roll/4-0530-shell-improvements

# 2. Create feature branch
git checkout -b feature/zellij-config

# 3. Make changes to Zellij config
vi home/gig/common/shell/zellij/default.nix

# 4. Test on current host
just rebuild

# 5. Integrate into roll
git checkout roll/4-0530-shell-improvements
just roll-integrate feature/zellij-config

# 6. Work on another feature in the same roll
git checkout -b feature/starship-tweaks
# ... make changes ...
just roll-integrate feature/starship-tweaks

# 7. Graduate roll to rolling when satisfied
just roll-graduate

# 8. Test on other hosts
ssh merlin "cd ~/.dotfiles && git checkout rolling && git pull && just rebuild"
ssh ganoslal "cd ~/.dotfiles && git checkout rolling && git pull && just rebuild"

# 9. Fix issues if needed
git checkout -b fix/merlin-display rolling
# ... fix merlin-specific issue ...
git checkout rolling
git merge --no-ff fix/merlin-display
git push

# 10. Promote to main when all hosts verified
just roll-promote
```

## Understanding Your Existing Rolls

Looking at your current branches:

```bash
roll/1-0527-bringing-forth-old-stuff   # Roll 1: Resurrect old configs
roll/2-0527-opencode-mcp-expansion     # Roll 2: MCP server work  
roll/3-lock-26.05                      # Roll 3: NixOS 26.05 migration
```

These are **sequential integration checkpoints**. Each represents a batch of related changes that were tested together before moving to `rolling-transitional-phase`.

### Recommended Actions

**Option A: Continue with existing rolls**
```bash
# If roll/3 is complete, graduate it
git checkout roll/3-lock-26.05
just roll-graduate  # Merges to rolling

# Start next roll
just roll-start <next-theme>
```

**Option B: Clean slate**
```bash
# Merge all completed rolls to rolling
git checkout rolling
git merge --no-ff roll/1-0527-bringing-forth-old-stuff
git merge --no-ff roll/2-0527-opencode-mcp-expansion  
git merge --no-ff roll/3-lock-26.05

# Archive old rolls (optional)
git branch -d roll/1-0527-bringing-forth-old-stuff
git branch -d roll/2-0527-opencode-mcp-expansion
git branch -d roll/3-lock-26.05

# Start fresh
just roll-start current-work
```

## Best Practices

### ✅ Do

- **Use descriptive themes** for rolls (e.g., "display-config", not "fixes")
- **Test incrementally** - Build and test after each feature integration
- **Graduate frequently** - Don't let rolls get too large
- **Keep feature branches small** - One logical change per branch
- **Use worktrees** for parallel work on different rolls

### ❌ Don't

- **Don't merge directly to main** - Always go through rolling
- **Don't delete rolls immediately** - Keep for reference until merged to main
- **Don't mix unrelated changes** in a single roll
- **Don't promote untested code** to main

## Advanced Usage

### Parallel Rolls with Worktrees

```bash
# Work on two rolls simultaneously
git worktree add worktrees/roll-5 -b roll/5-0530-wayland-migration
git worktree add worktrees/roll-6 -b roll/6-0530-monitoring-setup

# Work in first worktree
cd worktrees/roll-5
# ... make wayland changes ...
just rebuild

# Work in second worktree  
cd worktrees/roll-6
# ... make monitoring changes ...
just rebuild

# Back to main repo
cd ../..
```

### Host-Specific Testing Branches

```bash
# Create host-specific test branch from a roll
git checkout -b ganoslal/test-displays roll/4-0530-shell-improvements

# Make ganoslal-specific experiments
# ... changes ...

# If successful, merge back to roll
git checkout roll/4-0530-shell-improvements
git merge --no-ff ganoslal/test-displays
```

### Emergency Hotfixes

```bash
# Critical fix needed in main
git checkout -b hotfix/critical-fix main

# Fix the issue
# ... changes ...

# Fast-track to main (skip rolling)
git checkout main
git merge --no-ff hotfix/critical-fix
git push

# Also merge to rolling to keep it current
git checkout rolling
git merge main
git push
```

## Troubleshooting

### "Not currently on a roll branch"

You need to either:
- Create a new roll: `just roll-start <theme>`
- Switch to existing roll: `git checkout roll/N-*`

### Merge conflicts during graduation

```bash
# Resolve conflicts manually
git checkout rolling
git merge roll/N-description  # Will show conflicts
# ... resolve conflicts ...
git add .
git commit
git push
```

### Want to abandon a roll

```bash
# Just delete the branch (if not pushed)
git checkout rolling
git branch -D roll/N-description

# If pushed, delete locally and remotely
git push origin --delete roll/N-description
```

## Configuration

Roll flow stores configuration in `~/.config/roll-flow/config.nuon`:

```nushell
{
  repo_root: "/home/gig/.dotfiles",
  rolling_branch: "rolling",
  stable_branch: "main", 
  roll_prefix: "roll/",
  hosts: ["ganoslal", "merlin", "wsl"]
}
```

You can edit this to customize:
- Branch names
- Host list for testing
- Roll numbering prefix

## Integration with Fleet Protocols

Roll Flow integrates with [Lord Gig's Fleet Operations](../operations/fleet-management/OPERATIONS-MANUAL.md):

- **Quest Reports**: Major rolls should have corresponding quest reports
- **Engineering Logs**: Use `.tmp-oc-logs/` for research during roll development
- **Commit Standards**: All roll commits follow fleet git standards

---

**Chief Engineer Montgomery Scott**  
**Stardate 2026-05-30**

*"The more ye' organize yer changes into themed rolls, the easier it is to track down what broke. Trust me, I've rolled back enough experimental engine modifications to know!"*
