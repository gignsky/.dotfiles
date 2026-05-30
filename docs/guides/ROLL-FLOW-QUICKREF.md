# Roll Flow Quick Reference

**Git workflow for NixOS multi-host configurations**

## Quick Start

```bash
just roll-init              # One-time setup
just roll-init --rolling-branch <name>  # Custom branch name
just roll-start <theme>     # Begin new work batch
just roll-integrate <branch> # Add feature to current roll
just roll-graduate          # Move roll → rolling
just roll-promote           # Move rolling → main (after testing all hosts)
```

## Branch Flow

```
feature → roll/N → rolling → main
          (theme)  (tested  (verified
                    on some) on all)
```

## Common Workflows

### New Feature Development

```bash
just roll-start display-fixes
git checkout -b feature/ganoslal-monitors
# ... work ...
just rebuild
just roll-integrate feature/ganoslal-monitors
just roll-graduate
```

### Testing Across Hosts

```bash
# On merlin
git checkout rolling && git pull
just rebuild

# On ganoslal  
git checkout rolling && git pull
just rebuild

# All working? Promote!
just roll-promote
```

### Parallel Work (Worktrees)

```bash
git worktree add worktrees/shell-work -b roll/5-shell
git worktree add worktrees/display-work -b roll/6-displays

cd worktrees/shell-work
# ... work on shell improvements ...

cd ../display-work
# ... work on display config ...
```

## Roll Naming Convention

```
roll/<number>-<MMDD>-<theme>

Examples:
- roll/4-0530-shell-improvements
- roll/5-0601-display-config
- roll/6-0602-nixos-26.05-migration
```

## Status Checks

```bash
just roll-status    # Current roll info
just roll-list      # All rolls
just roll-test-all  # Build all hosts (no deploy)
git log --graph --oneline --all -20  # Visual branch history
```

## When to...

### Start a new roll
- ✅ Beginning themed work (shell, displays, monitoring)
- ✅ After graduating previous roll
- ✅ When switching focus areas

### Graduate to rolling
- ✅ Builds successfully on target host
- ✅ Basic testing complete
- ❌ Doesn't need to work on all hosts yet

### Promote to main
- ✅ Tested on **ganoslal**
- ✅ Tested on **merlin**
- ✅ Tested on **wsl**
- ✅ No known issues

## Emergency Procedures

### Quick fix to main
```bash
git checkout -b hotfix/critical main
# ... fix ...
git checkout main && git merge --no-ff hotfix/critical
git checkout rolling && git merge main
```

### Abandon a roll
```bash
git checkout rolling
git branch -D roll/N-description
```

### Resolve conflicts
```bash
git checkout rolling
git merge roll/N-description
# ... resolve conflicts ...
git add . && git commit
```

## Tips

💡 **Keep rolls small** - Graduate frequently  
💡 **Test incrementally** - Build after each feature  
💡 **Use worktrees** - Parallel work on different themes  
💡 **Descriptive themes** - Future you will thank you  
💡 **Don't skip rolling** - Never merge directly to main  

## Full Documentation

See [docs/guides/ROLL-FLOW-WORKFLOW.md](./ROLL-FLOW-WORKFLOW.md) for complete guide.

---

*"A well-organized roll is like a properly tuned warp core - smooth, predictable, and won't blow up in yer face!"*  
— Chief Engineer Montgomery Scott
