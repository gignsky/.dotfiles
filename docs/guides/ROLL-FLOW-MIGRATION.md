# Migrating to Roll Flow

**Converting your existing branches to the Roll Flow system**

## Current State Analysis

Your repository currently has these branches:

```bash
# Current rolls (numbered integration branches)
roll/1-0527-bringing-forth-old-stuff
roll/2-0527-opencode-mcp-expansion
roll/3-lock-26.05

# Integration branch
rolling-transitional-phase

# Development branches
develop
small-updates
update-taskbars

# Feature branches
feature/monitors-working-everywhere
dev/thunderbird
spacedock/init

# Host-specific branches
ganoslal/2-fixing-displays
merlin/outdoor-displays

# Stable branch
main
```

## Migration Strategy

You have **two migration options**:

### Option A: Clean Migration (Recommended)

Start fresh with a clean Roll Flow setup. Best if your current rolls are mostly complete.

### Option B: Gradual Migration

Integrate existing rolls one by one while continuing to use the system. Best if you have active work in progress.

---

## Option A: Clean Migration

### Step 1: Consolidate Existing Work

```bash
# Navigate to repo
cd ~/.dotfiles

# Ensure you're on rolling branch
git checkout rolling-transitional-phase

# Merge all completed rolls
git merge --no-ff roll/1-0527-bringing-forth-old-stuff
git merge --no-ff roll/2-0527-opencode-mcp-expansion
git merge --no-ff roll/3-lock-26.05

# Merge any completed development branches
git merge --no-ff develop
git merge --no-ff small-updates
git merge --no-ff update-taskbars

# Push consolidated rolling branch
git push
```

### Step 2: Rename Rolling Branch

```bash
# Rename rolling-transitional-phase → rolling
git branch -m rolling-transitional-phase rolling
git push origin -u rolling

# Delete old remote branch
git push origin --delete rolling-transitional-phase
```

### Step 3: Initialize Roll Flow

```bash
# Initialize the roll-flow system
just roll-init

# Start your first new roll
just roll-start current-work
```

### Step 4: Clean Up Old Branches

```bash
# Archive old rolls (they're merged into rolling)
git branch -d roll/1-0527-bringing-forth-old-stuff
git branch -d roll/2-0527-opencode-mcp-expansion
git branch -d roll/3-lock-26.05

# Delete merged development branches
git branch -d develop
git branch -d small-updates
git branch -d update-taskbars

# Delete remote tracking branches
git push origin --delete roll/1-0527-bringing-forth-old-stuff
git push origin --delete roll/2-0527-opencode-mcp-expansion
git push origin --delete roll/3-lock-26.05
git push origin --delete develop
```

### Step 5: Handle Active Feature Branches

```bash
# For active feature branches, rebase onto new rolling
git checkout feature/monitors-working-everywhere
git rebase rolling

# Then integrate into your new roll
git checkout roll/4-<current-date>-current-work
just roll-integrate feature/monitors-working-everywhere
```

### Step 6: Test and Promote to Main

```bash
# Test on all hosts
just roll-test-all

# When ready, graduate
just roll-graduate

# Test rolling on each host
# (SSH to each host and run: git checkout rolling && git pull && just rebuild)

# When all hosts verified, promote
just roll-promote
```

---

## Option B: Gradual Migration

### Step 1: Rename Rolling Branch

```bash
cd ~/.dotfiles

# Rename rolling-transitional-phase → rolling
git branch -m rolling-transitional-phase rolling
git push origin -u rolling
git push origin --delete rolling-transitional-phase
```

### Step 2: Initialize Roll Flow

```bash
# Initialize roll-flow
just roll-init

# This doesn't affect existing branches
```

### Step 3: Continue Existing Rolls

You can continue using your existing `roll/*` branches:

```bash
# Work on existing roll
git checkout roll/3-lock-26.05

# Add features to it
git checkout -b feature/new-thing
# ... work ...

# Integrate (manual merge since it's pre-roll-flow)
git checkout roll/3-lock-26.05
git merge --no-ff feature/new-thing

# When done, graduate it
git checkout rolling
git merge --no-ff roll/3-lock-26.05
git push
```

### Step 4: Start New Rolls with Roll Flow

```bash
# For NEW work, use roll-flow
just roll-start nixos-config-improvements

# This creates roll/4-MMDD-nixos-config-improvements
# Now you can use just roll-integrate, etc.
```

### Step 5: Gradual Cleanup

As you complete and graduate old rolls, delete them:

```bash
# After roll/3 is merged to rolling and main
git branch -d roll/3-lock-26.05
git push origin --delete roll/3-lock-26.05
```

### Step 6: Merge Development Branches

```bash
# When ready, consolidate develop into rolling
git checkout rolling
git merge --no-ff develop
git branch -d develop
git push origin --delete develop
```

---

## Migration Checklist

Use this checklist to track your migration progress:

### Pre-Migration
- [ ] Review all active branches and their status
- [ ] Identify which rolls/features are complete vs. in-progress
- [ ] Back up current branch state: `git branch > branch-backup.txt`
- [ ] Ensure all important work is pushed to remote

### Core Migration
- [ ] Rename `rolling-transitional-phase` → `rolling`
- [ ] Update remote tracking for rolling branch
- [ ] Run `just roll-init`
- [ ] Test roll-flow commands work: `just roll-status`

### Branch Consolidation
- [ ] Merge completed `roll/*` branches to rolling
- [ ] Merge or rebase active feature branches
- [ ] Handle host-specific branches (merge or keep as testing branches)
- [ ] Delete merged branches locally and remotely

### Verification
- [ ] Test build on ganoslal: `just rebuild`
- [ ] Test build on merlin: `just rebuild`
- [ ] Test build on wsl: `just rebuild`
- [ ] Verify `just roll-status` shows correct state
- [ ] Verify `just roll-list` shows expected rolls

### First New Roll
- [ ] Start first new roll: `just roll-start <theme>`
- [ ] Create and integrate a feature branch
- [ ] Test the full workflow: integrate → graduate → promote
- [ ] Verify all commands work as expected

### Cleanup
- [ ] Archive old roll branches
- [ ] Update any documentation referencing old branch names
- [ ] Clean up remote branches
- [ ] Create git tag to mark migration point: `git tag migration-to-roll-flow`

---

## Common Migration Issues

### Issue: "Rolling branch doesn't exist"

**Solution:**
```bash
# If you renamed it correctly, set upstream
git branch --set-upstream-to=origin/rolling rolling

# Or create it from rolling-transitional-phase
git checkout rolling-transitional-phase
git checkout -b rolling
git push -u origin rolling
```

### Issue: "Merge conflicts during consolidation"

**Solution:**
```bash
# When merging old rolls
git merge --no-ff roll/N-description
# ... conflicts occur ...

# Resolve each conflict manually
git status  # See conflicted files
# Edit files to resolve conflicts
git add <resolved-files>
git commit

# Continue with next merge
```

### Issue: "Lost track of which branches are merged"

**Solution:**
```bash
# Show branches merged into rolling
git branch --merged rolling

# Show branches NOT merged into rolling
git branch --no-merged rolling

# Visual graph to see relationships
git log --graph --oneline --all --decorate -20
```

### Issue: "Roll-flow commands not working"

**Solution:**
```bash
# Ensure script is executable
chmod +x ~/.dotfiles/scripts/roll-flow

# Test script directly
~/.dotfiles/scripts/roll-flow status

# Reinitialize if needed
just roll-init
```

---

## Rollback Plan

If migration causes issues, you can revert:

```bash
# Restore original rolling branch name
git branch -m rolling rolling-transitional-phase
git push origin -u rolling-transitional-phase

# Remove roll-flow config
rm -rf ~/.config/roll-flow

# Restore old branches from backup
git checkout -b develop origin/develop  # If still on remote
```

---

## Post-Migration Best Practices

### Document Your Transition

Create a commit documenting the migration:

```bash
git checkout main
git commit --allow-empty -m "chore: migrated to Roll Flow workflow system

- Renamed rolling-transitional-phase → rolling
- Consolidated historical roll/* branches
- Initialized roll-flow tooling
- See docs/guides/ROLL-FLOW-WORKFLOW.md for new workflow

Chief-Engineer: Montgomery Scott <$(date)>
Migration-Completed: $(date +%Y-%m-%d)
"
```

### Update Team/Personal Documentation

If you work with others or want to remember:

1. Add note in main README about Roll Flow
2. Update any scripts that referenced old branch names
3. Update CI/CD if you have any
4. Document migration date and reasoning

### First Real Roll

Start your first real roll with something small to test the workflow:

```bash
just roll-start shell-tweaks

# Make a small, safe change
git checkout -b feature/starship-symbol
# Edit something minor
just rebuild  # Test it

# Integrate
just roll-integrate feature/starship-symbol

# Graduate quickly
just roll-graduate

# Test on one other host
# Then promote to verify the full cycle works
just roll-promote
```

---

## Timeline Recommendations

### Quick Migration (2-3 hours)
Best if you have mostly completed work and want a clean slate.

1. ⏱️ **30 min**: Consolidate all rolls into rolling
2. ⏱️ **15 min**: Rename and initialize roll-flow
3. ⏱️ **30 min**: Clean up old branches
4. ⏱️ **45 min**: Test on all hosts
5. ⏱️ **30 min**: First new roll cycle test

### Gradual Migration (over 1-2 weeks)
Best if you have active work and want to minimize disruption.

1. **Week 1, Day 1**: Initialize roll-flow, continue using existing rolls
2. **Week 1, Days 2-5**: Finish current work, start using new roll commands for new work
3. **Week 2, Day 1-2**: Consolidate completed old rolls
4. **Week 2, Day 3-4**: Test full workflow with new rolls
5. **Week 2, Day 5**: Clean up old branches

---

**Chief Engineer Montgomery Scott**  
**Stardate 2026-05-30**

*"Migration is like a warp core upgrade - ye' can do it fast with risk, or slow with safety. I recommend the latter, but I've done both!"*
