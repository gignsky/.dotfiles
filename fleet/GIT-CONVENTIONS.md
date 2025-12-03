# Realm of Reason - Git & Development Conventions

**Authority**: Lord Gig's Realm  
**Purpose**: Standardized practices for technical operations across the realm

## Git Commit Philosophy

### Clean History Principles
- **Each commit should represent meaningful progress** toward a goal
- **Avoid "oops" commits** followed by "fix the oops" commits  
- **Future crew members** should be able to understand the progression of work by reading commit history
- **Repository archaeology** should reveal clear decision-making and implementation patterns

### Test Commits & Experimental Work
- **Test commits are ephemeral** and should be properly cleaned up
- **Use `git revert`** rather than `git reset` for undoing shared commits
- **Demonstrate respect** for repository long-term readability

## Revert vs Reset Guidelines

### When to Use `git revert` (Recommended)
- **Undoing commits that have been pushed** to shared repositories
- **Maintaining visible history** of what was changed and why it was undone
- **Safe operation** that doesn't rewrite history
- **Creates new commit** with message format: `Revert "Original commit message"`

**Example:**
```bash
git revert HEAD               # Revert most recent commit
git revert abc123            # Revert specific commit
git revert --no-edit HEAD    # Skip edit prompt for revert message
```

### When `git reset` Might Be Appropriate  
- **Local commits that haven't been pushed** (use with extreme caution)
- **Immediate fixes to most recent commit** via `git commit --amend`
- **Never use on shared/pushed commits** - this rewrites history unsafely

### Multiple Commit Reverts
For reverting several commits, work **backward** from most recent:
```bash
git revert HEAD          # Revert most recent first
git revert HEAD~1        # Then previous one
git revert HEAD~2        # And so on...
```

## Commit Message Standards

### Format Guidelines
- **First line**: Brief, clear summary (50 characters or less)
- **Body** (if needed): Detailed explanation after blank line
- **Use present tense**: "Add feature" not "Added feature"  
- **Include context**: Why the change was made, not just what changed

### Examples of Good Commit Messages
```
Add USS registry system to fleet operations manual

- Implements commit-count based registry numbers
- Updates ship naming conventions throughout documentation  
- Establishes proper naval hierarchy for realm libraries
```

```
Fix scotty-post-commit-log hook leaving uncommitted files

- Disables problematic hooks that violated git workflow
- Prevents infinite loop of uncommitted log entries
- Maintains logging capability through manual processes
```

## Documentation Standards

### Change Logs & Context
- **All significant changes** should be documented with context
- **Authority attribution** for who authorized changes
- **Implementation tracking** for who executed changes
- **Append rather than replace** existing documentation where possible

### File Naming Conventions  
- **Use kebab-case** for .nix files: `hardware-configuration.nix`
- **Use descriptive names** that indicate purpose
- **Include dates** in log files: `YYYY-MM-DD-description.log`

---

**Established by Captain Montgomery Scott**  
**Authorized by Lord Gig**  
**Stardate: 2025-12-03**

*Subject to review and refinement with administrative support*