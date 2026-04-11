# Commander Una's Responses to Lord Gig's Questions

**Stardate:** 2026-04-10  
**Officer:** Commander Una Chin-Riley  
**Subject:** tmp-oc-logs archival and branch reset strategy

---

## Question 1: Confirmation of tmp-oc-logs → Annex Archival

**Lord Gig asked:** "Please confirm that at some point the items in the tmp-oc-logs/ dir will be saved appropriately in the annex?"

### Answer: Yes, But Not Automatically

**Current State:**
- `.tmp-oc-logs/` is NOT in `.gitignore` (I checked)
- Files ARE visible to git and CAN be committed
- However, there's no automatic process to move them to annex

**Current Files in .tmp-oc-logs/:**
```
scotty-vm-sops-engineering-log.md          (7.1K) - April 2
vm-secrets-research-report.md             (20K) - April 2 (Library Computer)
vm-sops-implementation-plan.md            (13K) - April 2 (Implementation plan)
una-nixpkgs-patch-proposal-analysis.md    (13K) - April 10 (TODAY)
2026-02-27_hm-rebuild-merlin-gen146.log   (2.7K) - March 30
```

**These SHOULD be archived** - they contain valuable research and engineering analysis.

### Recommended Archival Locations

Based on annex structure (`/home/gig/local_repos/annex/`):

#### 1. Engineering Logs → Scotty's Logs
**Target:** `annex/crew-logs/scotty/engineering-logs/2026-04/`
```bash
scotty-vm-sops-engineering-log.md → 2026-04-02-vm-sops-implementation.md
```

#### 2. Research Reports → Library Computer Logs
**Target:** `annex/crew-logs/library-computer/research-logs/2026-04/`
```bash
vm-secrets-research-report.md → 2026-04-02-vm-secrets-research.md
vm-sops-implementation-plan.md → 2026-04-02-vm-sops-implementation-plan.md
```

#### 3. Command Analysis → Fleet Operations
**Target:** `annex/fleet/operations/reports/`
```bash
una-nixpkgs-patch-proposal-analysis.md → 2026-04-10-nixpkgs-vm-secrets-proposal-analysis.md
```

#### 4. System Logs → Computer Logs
**Target:** `annex/computer-logs/`
```bash
2026-02-27_hm-rebuild-merlin-gen146.log → (keep as is)
```

---

## Question 2: Branch Reset Strategy

**Lord Gig asked:** "I'd like to somehow reset the branch through a new commit to the point before we start working with credentials and tell me what the general consensus is on the best way to do this..."

### Understanding the Goal

You want to:
1. **Preserve the work done** (VM key implementation + research)
2. **Reset the branch** to before VM credentials work started
3. **Keep history available** for future reference
4. **NOT lose the commits** (they might be useful later)

### Git Options Analysis

#### Option 1: Create New Branch from Earlier Point (RECOMMENDED)

**Concept:** Leave current branch intact, create new branch from earlier commit

**Commands:**
```bash
cd ~/.dotfiles

# Identify the commit before VM work started
git log --oneline vm/1-attempt-vm-secrets-import

# Create new branch from that point
git branch vm/2-systemd-credentials-approach c40675c9  # "docs(vm): add VM sops secrets research"
git checkout vm/2-systemd-credentials-approach

# Or in one command:
git checkout -b vm/2-systemd-credentials-approach c40675c9
```

**Advantages:**
- ✅ Original branch (`vm/1-attempt-vm-secrets-import`) stays intact
- ✅ All commits preserved for reference
- ✅ Clean starting point for new approach
- ✅ Can cherry-pick useful commits later if needed

**Disadvantages:**
- ⚠️ Two branches to manage temporarily

#### Option 2: Revert Commits with Explanatory Commit

**Concept:** Create revert commits that undo the VM key work

**Commands:**
```bash
cd ~/.dotfiles
git checkout vm/1-attempt-vm-secrets-import

# Revert the two VM key implementation commits
git revert --no-commit af142b4b  # neededForUsers fix
git revert --no-commit bc34f350  # VM key embedding fix
git revert --no-commit aa474490  # VM key copy to /etc
git revert --no-commit 308c9d5b  # VM key detection

# Create single revert commit with explanation
git commit -m "revert(vm-sops): remove VM key approach in favor of systemd credentials

Previous implementation used builtins.readFile which exposed secrets in
/nix/store (world-readable). Reverting to clean state before implementing
systemd credentials approach.

Previous commits preserved for reference:
- af142b4b: neededForUsers fix
- bc34f350: VM key embedding
- aa474490: VM key /etc copy  
- 308c9d5b: VM key detection

Research findings in .tmp-oc-logs/ will be archived to annex.

Rationale: Commander Una's analysis revealed virtualisation.credentials
is the correct upstream solution. See una-nixpkgs-patch-proposal-analysis.md"
```

**Advantages:**
- ✅ Clear history showing decision to change approach
- ✅ Single branch to manage
- ✅ All commits remain in history
- ✅ Explicit documentation of "why we changed direction"

**Disadvantages:**
- ⚠️ History becomes slightly more complex (forward commits + revert commits)

#### Option 3: Interactive Rebase (DESTRUCTIVE - Not Recommended)

**Concept:** Rewrite history to remove commits

```bash
git rebase -i c40675c9^  # Before VM work
# Mark commits as "drop" in editor
```

**Why NOT Recommended:**
- ❌ **LOSES the work completely** (no reference)
- ❌ Forces push required if branch was pushed
- ❌ Violates Lord Gig's requirement to keep work for reference

#### Option 4: Soft Reset + New Commit (HYBRID)

**Concept:** Reset branch pointer but keep changes in working tree, then commit explanation

**Commands:**
```bash
cd ~/.dotfiles
git checkout vm/1-attempt-vm-secrets-import

# Soft reset to before VM work (keeps changes as uncommitted)
git reset --soft c40675c9

# Changes now in staging area - unstage them
git reset HEAD

# Create marker commit explaining the reset
git commit --allow-empty -m "reset: returning to pre-VM-key state for systemd credentials approach

All VM key implementation work (af142b4b through bc34f350) is being
abandoned in favor of systemd credentials approach.

Research and implementation preserved in:
- .tmp-oc-logs/scotty-vm-sops-engineering-log.md
- .tmp-oc-logs/vm-secrets-research-report.md  
- .tmp-oc-logs/una-nixpkgs-patch-proposal-analysis.md

These will be archived to annex before final merge.

Previous commits are preserved in git reflog for 90 days if needed."
```

**Advantages:**
- ✅ Clean branch state
- ✅ Work preserved in reflog temporarily
- ✅ Clear marker commit

**Disadvantages:**
- ⚠️ Commits only in reflog (not permanent)
- ⚠️ Will be garbage collected after 90 days

### My Recommendation: **Option 1 (New Branch)**

**Why:**
1. ✅ Safest - preserves everything permanently
2. ✅ Clearest - two distinct approaches in two branches
3. ✅ Most flexible - can compare approaches or cherry-pick later
4. ✅ Standard Git workflow

**Implementation:**
```bash
cd ~/.dotfiles

# Archive tmp-oc-logs first (see Question 3)
# ... archival commands ...

# Create new branch from before VM key work
git checkout -b vm/2-systemd-credentials-approach c40675c9

# Verify you're at the right point
git log --oneline -5
# Should show c40675c9 as HEAD

# Now ready to implement systemd credentials approach
```

**Branch Lifecycle:**
```
vm/1-attempt-vm-secrets-import (REFERENCE)
  ├─ c40675c9: docs(vm): research
  ├─ 308c9d5b: feat(sops): VM key detection
  ├─ aa474490: fix(sops): VM key copy
  ├─ bc34f350: fix(vm-sops): key embedding
  └─ af142b4b: fix(vm-sops): neededForUsers ← Current state (FROZEN)

vm/2-systemd-credentials-approach (ACTIVE)
  └─ c40675c9: docs(vm): research ← Starting point
      └─ [new commits for systemd credentials]
```

---

## Question 3: Protocol for tmp-oc-logs Archival

**Lord Gig asked:** "How can we ensure that the proper protocol is to make sure that tmp-oc-logs always get filed away in the annex at least by the end of a branch's life?"

### Proposed Protocol

#### Protocol: End-of-Branch Log Archival

**Trigger Points:**
1. Before merging feature branch to develop
2. Before deleting abandoned branch
3. At end of major investigation/research phase
4. When branch is being reset/rebased significantly

**Responsibility:** 
- Branch author or last active agent
- Commander Una for strategic decision branches
- Scotty for engineering branches
- Library Computer for research branches

#### Step-by-Step Archival Process

**Phase 1: Review & Categorize** (5-10 minutes)
```bash
cd ~/.dotfiles
ls -lh .tmp-oc-logs/

# Identify file types:
# - Engineering logs → scotty/engineering-logs/YYYY-MM/
# - Research reports → library-computer/research-logs/YYYY-MM/
# - Command analysis → fleet/operations/reports/
# - System logs → computer-logs/
```

**Phase 2: Prepare Annex Directories** (2-3 minutes)
```bash
cd ~/local_repos/annex

# Create date-based directories if needed
mkdir -p crew-logs/scotty/engineering-logs/$(date +%Y-%m)
mkdir -p crew-logs/library-computer/research-logs/$(date +%Y-%m)
```

**Phase 3: Move Files with Context** (10-15 minutes)
```bash
# Move with descriptive renaming
cp ~/.dotfiles/.tmp-oc-logs/scotty-vm-sops-engineering-log.md \
   crew-logs/scotty/engineering-logs/2026-04/2026-04-02-vm-sops-implementation.md

cp ~/.dotfiles/.tmp-oc-logs/vm-secrets-research-report.md \
   crew-logs/library-computer/research-logs/2026-04/2026-04-02-vm-secrets-research.md

cp ~/.dotfiles/.tmp-oc-logs/una-nixpkgs-patch-proposal-analysis.md \
   fleet/operations/reports/2026-04-10-nixpkgs-vm-secrets-proposal.md
```

**Phase 4: Create Index Entry** (5 minutes)
```bash
# Update crew-logs README or create manifest
cat >> crew-logs/scotty/engineering-logs/2026-04/INDEX.md << EOF
## 2026-04-02 - VM Sops Implementation (Branch: vm/1-attempt-vm-secrets-import)

**Context:** Investigation into enabling sops secrets in NixOS VMs

**Files:**
- 2026-04-02-vm-sops-implementation.md - Engineering implementation log
- Related research: see library-computer/research-logs/2026-04/

**Outcome:** Approach abandoned in favor of systemd credentials
**Reference:** See fleet/operations/reports/2026-04-10-nixpkgs-vm-secrets-proposal.md
EOF
```

**Phase 5: Commit to Annex** (2 minutes)
```bash
cd ~/local_repos/annex
git add crew-logs/ fleet/operations/reports/
git commit -m "docs: archive VM sops research from vm/1-attempt branch

Archived research and engineering logs from ~/.dotfiles branch
vm/1-attempt-vm-secrets-import before branch reset.

Files archived:
- scotty-vm-sops-engineering-log.md → scotty/engineering-logs/2026-04/
- vm-secrets-research-report.md → library-computer/research-logs/2026-04/
- una-nixpkgs-patch-proposal-analysis.md → fleet/operations/reports/

Branch Context: Investigation revealed systemd credentials as superior
approach to VM secrets injection. Original VM key approach preserved
for reference but not implemented.

[ ] Reviewed by Lord G.
---
Filed by: Commander Una Chin-Riley
Date: $(date -Iseconds)
Branch: vm/1-attempt-vm-secrets-import → vm/2-systemd-credentials-approach"

git push
```

**Phase 6: Clean dotfiles tmp-oc-logs** (1 minute)
```bash
# After confirming annex commit pushed successfully
cd ~/.dotfiles
rm .tmp-oc-logs/scotty-vm-sops-engineering-log.md
rm .tmp-oc-logs/vm-secrets-research-report.md
rm .tmp-oc-logs/una-nixpkgs-patch-proposal-analysis.md

# Optional: Add note about where they went
cat > .tmp-oc-logs/ARCHIVED-$(date +%Y-%m-%d).txt << EOF
Files from this directory archived to ~/local_repos/annex/ on $(date)

See annex commit: [commit-hash]
Archived by: Commander Una

Files moved:
- scotty-vm-sops-engineering-log.md
- vm-secrets-research-report.md  
- una-nixpkgs-patch-proposal-analysis.md
EOF

git add .tmp-oc-logs/
git commit -m "docs: archived tmp-oc-logs to annex

Moved research logs to annex before branch reset.
See annex commit [commit-hash] for archived content."
```

**Total Time:** ~30 minutes

#### Automation Opportunity: Just Command

**Create:** `just archive-logs [branch-name]`

```bash
# In justfile
archive-logs branch="current":
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "📦 Archiving .tmp-oc-logs/ to annex..."
    
    BRANCH_NAME="{{ branch }}"
    DATE=$(date +%Y-%m-%d)
    MONTH_DIR=$(date +%Y-%m)
    
    cd ~/local_repos/annex
    
    # Create directories
    mkdir -p "crew-logs/scotty/engineering-logs/$MONTH_DIR"
    mkdir -p "crew-logs/library-computer/research-logs/$MONTH_DIR"
    mkdir -p "fleet/operations/reports"
    
    # Copy files (with user confirmation)
    for file in ~/.dotfiles/.tmp-oc-logs/*.md; do
        [ -f "$file" ] || continue
        basename=$(basename "$file")
        echo "Archive $basename? (y/N)"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            # Prompt for destination
            echo "Destination? (1=scotty, 2=library-computer, 3=fleet-reports)"
            read -r dest
            case $dest in
                1) cp "$file" "crew-logs/scotty/engineering-logs/$MONTH_DIR/$DATE-$basename" ;;
                2) cp "$file" "crew-logs/library-computer/research-logs/$MONTH_DIR/$DATE-$basename" ;;
                3) cp "$file" "fleet/operations/reports/$DATE-$basename" ;;
            esac
        fi
    done
    
    echo "✅ Files copied. Review and commit manually."
    echo "Next: cd ~/local_repos/annex && git status"
```

#### Checklist Template

**Add to AGENTS.md or create ARCHIVAL-CHECKLIST.md:**

```markdown
## End-of-Branch Log Archival Checklist

Before merging or deleting branch:

- [ ] Review all files in `.tmp-oc-logs/`
- [ ] Categorize by type (engineering/research/command/system)
- [ ] Create month directories in annex if needed
- [ ] Copy files with descriptive naming (YYYY-MM-DD-description.md)
- [ ] Create or update INDEX.md in target directory
- [ ] Commit to annex with context about branch/investigation
- [ ] Push annex changes
- [ ] Clean .tmp-oc-logs/ or create ARCHIVED note
- [ ] Commit .tmp-oc-logs/ cleanup to dotfiles
- [ ] Verify annex files accessible via git log/search

**Archival locations:**
- Engineering logs → `annex/crew-logs/scotty/engineering-logs/YYYY-MM/`
- Research reports → `annex/crew-logs/library-computer/research-logs/YYYY-MM/`
- Command analysis → `annex/fleet/operations/reports/`
- System logs → `annex/computer-logs/`
```

### Long-term Protocol Enhancement

**Add to AGENTS.md:**

```markdown
## Universal Agent Protocol: tmp-oc-logs Archival

**When:** At end of branch lifecycle or major investigation
**Who:** Last active agent on branch
**Where:** ~/local_repos/annex/ (appropriate crew-logs/ subdirectory)

**Required Actions:**
1. Review .tmp-oc-logs/ for archival-worthy content
2. Move to annex with descriptive naming and context
3. Create INDEX.md entry documenting investigation
4. Commit to annex with branch context
5. Clean .tmp-oc-logs/ after confirming annex push
6. Document archival in dotfiles commit

**Critical:** Research and engineering logs MUST be preserved.
Temporary logs are NOT temporary if they document decisions,
investigations, or significant technical work.

See: annex/crew-logs/README.md for filing structure
```

---

## Summary Answers

### Question 1: Will tmp-oc-logs be saved to annex?
**Yes, but requires manual archival.** I've provided locations and process above.

### Question 2: Best way to reset branch while preserving work?
**Recommended: Create new branch from earlier commit** (`vm/2-systemd-credentials-approach`)
- Preserves all work in `vm/1-attempt-vm-secrets-import`
- Clean starting point for new approach
- Standard Git workflow

### Question 3: Protocol to ensure logs are archived?
**Implement End-of-Branch Archival Protocol:**
- Checklist in AGENTS.md
- Add to Universal Agent Commands
- Optional: Create `just archive-logs` automation
- Responsibility: Last active agent or branch owner

---

## Immediate Action Items

If Lord Gig approves:

1. **Archive current tmp-oc-logs/** (~30 min)
   ```bash
   # I can execute the archival process now
   ```

2. **Create new branch** (2 min)
   ```bash
   cd ~/.dotfiles
   git checkout -b vm/2-systemd-credentials-approach c40675c9
   ```

3. **Update AGENTS.md with archival protocol** (10 min)

4. **Test systemd credentials approach** (2-3 hours)

**Total commitment:** ~3-4 hours to clean slate + new approach

---

**Commander Una Chin-Riley**  
**Stardate 2026-04-10T21:00:00**

_"Proper documentation and archival protocols ensure institutional knowledge preservation across missions."_
