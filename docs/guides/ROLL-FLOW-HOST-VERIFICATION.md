# Roll Flow Host Verification Tracking

## Overview

Roll Flow now tracks which hosts have verified each roll with actual rebuilds. This helps you see at a glance which systems have been tested before promoting code to production.

## How It Works

### Verification Detection

The system searches git commit history for rebuild commit patterns:

**NixOS Rebuilds:**
```
merlin: generation 203 (switch)
ganoslal: generation 145 (boot)
```

**Home Manager Rebuilds:**
```
gig@merlin: 2026-05-30 18:19 : id 187 -> /nix/store/...
gig@ganoslal: 2026-05-29 14:32 : id 92 -> /nix/store/...
```

A host is considered **verified** for a roll when BOTH NixOS and home-manager rebuild commits are found.

### Search Strategy

**For Unmerged Rolls** (still in development):
- Finds the branch point where the roll diverged from `rolling`
- Searches `rolling` branch for rebuilds after that point
- Logic: If you rebuild on `rolling` after the roll started, that tests the roll's changes

**For Graduated Rolls** (merged to rolling):
- Finds the merge commit where the roll joined `rolling`
- Searches for rebuilds after the merge commit
- Logic: Rebuilds after merging confirm the integrated changes work

## Commands

### `just roll-list`

Shows all rolls with verification status:

```bash
$ just roll-list

=== All Rolls ===

    roll/1-0527-bringing-forth-old-stuff
      ✅ merlin
      ⏳ ganoslal, wsl
      
    roll/2-0527-opencode-mcp-expansion
      ✅ merlin
      ⏳ ganoslal, wsl
      
    roll/3-lock-26.05
      ✅ merlin
      ⏳ ganoslal, wsl
      
    roll/4-update-taskbars
      ⏳ ganoslal, merlin, wsl
      
  → roll/5-roll-flow-init (current)
      ⏳ ganoslal, merlin, wsl
```

**Symbols:**
- `✅` = Host has verified with rebuilds (both NixOS + home-manager)
- `⏳` = Host has NOT verified yet
- `→` = Currently active roll branch

### `just roll-status`

Shows detailed status of current roll:

```bash
$ just roll-status

=== Roll Flow Status ===

Current branch: roll/5-roll-flow-init
Rolling branch: rolling
Stable branch:  main

✓ On active roll: roll/5-roll-flow-init
  Theme: roll-flow-init
  Started: 2026-05-30
  Features integrated: 2

  Host Verification Status:
    ⏳ ganoslal - not verified
    ✅ merlin - verified
    ⏳ wsl - not verified

=== Recent Rolls ===
  roll/5 - roll-flow-init [active]
    Verified: 1/3 hosts
  roll/4 - update-taskbars [graduated]
    Verified: 0/3 hosts
```

## Verification Workflow

### 1. Development Phase (On Roll Branch)

```bash
# Create a new roll
just roll-start my-feature

# Make your changes
# ... edit files ...

# Switch to rolling and rebuild to test
git stash
git checkout rolling
just rebuild && just home    # Creates rebuild commits!
git checkout roll/N-my-feature
git stash pop

# Check verification status
just roll-status
# Should show current host as verified
```

### 2. Integration Phase (After Graduate)

```bash
# Graduate roll to rolling
just roll-graduate

# Now rebuild on ALL hosts from rolling branch
# On each host:
git checkout rolling
git pull
just rebuild && just home

# Check progress
just roll-list
# Should show more hosts verified
```

### 3. Production Promotion

```bash
# Try to promote
just roll-promote

# If any hosts unverified, you'll be blocked:
# ✗ Not all hosts have verified the latest roll!
# Missing verification for: ganoslal, wsl

# After all hosts verified:
just roll-promote
# ✓ All hosts verified! Promoting...
```

## Configuration

Hosts are configured in `~/.config/roll-flow/config.nuon`:

```nushell
{
  hosts: [ganoslal, merlin, wsl]
  username: "gig"
  # ...
}
```

The system checks for rebuilds on each configured host.

## WSL Instances

WSL instances are treated as separate hosts:
- `wsl` = Generic WSL configuration
- `wsl@ganoslal` = WSL running on ganoslal
- `wsl@merlin` = WSL running on merlin

The promote command checks WSL instances but issues warnings instead of blocking if they're missing (since WSL instances are optional).

## Benefits

### Safety
- Visual confirmation that changes have been tested
- Prevents promoting untested code to main
- Catch multi-host issues before production

### Visibility
- See testing progress at a glance
- Know which hosts need attention
- Track verification history

### Accountability
- Rebuild commits serve as audit trail
- Proves actual testing occurred
- Documents when/where testing happened

## Troubleshooting

**"Host shows unverified but I rebuilt"**
- Verify rebuild commits exist with `git log rolling --oneline --grep="hostname"`
- Check that BOTH NixOS and home-manager commits are present
- Ensure you rebuilt from the correct branch (rolling for graduated rolls)

**"All hosts show unverified for new roll"**
- Normal! Unmerged rolls check for rebuilds in rolling after branch point
- Either:
  - Graduate the roll and rebuild from rolling
  - Or rebuild from rolling branch (tests current state including roll changes)

**"Want to skip verification"**
- Currently not supported by design
- Verification exists to ensure safety
- If emergency needed, manually merge branches with git

## Technical Details

### Search Patterns

The verification system uses these git log patterns:

```nushell
# NixOS rebuild
git log rolling --oneline --grep="^hostname: generation"

# Home Manager rebuild  
git log rolling --oneline --grep="^username@hostname:"
```

### Branch Point Detection

```nushell
# Find where roll branched from rolling
git merge-base rolling roll/N-theme

# Check for rebuilds after that point
git log rolling "$branch_point..rolling"
```

### Merge Detection

```nushell
# Find roll merge commit
git log rolling --grep="Merge branch 'roll/N-theme'"
```

## Future Enhancements

Potential additions:
- Show timestamps of last verification
- Track individual NixOS vs home-manager status
- Optional `--force` flag for emergencies
- Verification report generation
- Integration with `test-all` command
- Auto-verify after successful builds

---

**Created:** 2026-05-30  
**Author:** Chief Engineer Montgomery Scott  
**Status:** Production Ready
