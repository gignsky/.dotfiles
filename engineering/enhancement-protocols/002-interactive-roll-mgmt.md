# Interactive Roll Graduate/Promote — System Enhancement Protocol

**Status**: Planning\
**Priority**: High\
**Estimated Scope**: 2-3 sessions\
**Lead Engineer**: Commander Data\
**Created**: 2026-05-31\
**Last Updated**: 2026-05-31

## Objective

Replace the current `roll-graduate` (roll → rolling) and `roll-promote` (rolling → main)
commands with a single unified interactive flow that analyzes fleet state, presents rolls
for selection, runs final checks on confirmation, performs safe merges, and offers optional
branch cleanup — all while keeping `develop` reintegrated with `main`.

The current graduation/promotion tools are thin wrappers around git merge with basic
verification checks. The user wants a tool that acts as a smart assistant: it sees the
full picture (which rolls are ready, what scope they affect, what verification exists),
presents options, executes safely, and cleans up after itself.

**Goals:**

- Single command (e.g., `roll-flow merge` or `roll-flow graduate`) handles both
  graduation and promotion
- Interactive presentation: show user which rolls are candidates, their verification
  status, scope, and dependencies
- User selects which rolls to promote (with dependency resolution)
- Final safety checks auto-run before merge:
  - `nix flake check` for all affected rolls
  - `nix build` for all hosts
  - Verification check (test-all commits)
- Always use regular `--no-ff` merge (never fast-forward) for traceability
- After merge, optionally delete the roll branch (default: no)
- Final step: rebase/integrate `develop` onto `main` so rolling branch stays current
- After each stage, present a summary of what was done

## Current Plan

- ~~Initial test-all structured commit format~~ ✓ (completed 2026-05-31)
- ~~Two-source verification (test-all + rolling rebuild)~~ ✓ (completed 2026-05-31)
- SEP creation for interactive flow ✦ (current)
- Design the interactive flow and command structure
- Implement unified `roll-flow merge` command
- Implement interactive roll selection with dependency resolution
- Implement pre-merge safety checks
- Implement post-merge branch cleanup and reintegration
- Testing and edge-case handling

## Technical Requirements

- [ ] **Command Structure**: Unified `roll-flow merge` (or `roll-flow graduate`) that
  detects current state and adapts
  - If on a roll branch: treat as graduation (roll → rolling)
  - If on rolling branch: treat as promotion (rolling → main)
  - If neither: present all rolls for selection
- [ ] **Interactive Selection**: Present roll candidates in a numbered list with:
  - Roll name, scope, verification status per-host
  - Dependency relationships (roll A depends on roll B)
  - Visual indicators for verified/unverified per host
  - Suggested default selection (verified rolls in order)
- [ ] **Dependency Resolution**: Before merging, ensure dependent rolls are also
  selected or warn user
- [ ] **Pre-Merge Checks**: Run before any merge:
  - `nix flake check` on each selected roll's branch
  - Verification status from test-all commits
  - Check for uncommitted changes
  - Check for conflicts with target branch
- [ ] **Merge Execution**: Perform `git merge --no-ff` for each selected roll in order
  - Always create a merge commit (no fast-forward)
  - Use structured commit message referencing the roll
- [ ] **Post-Merge Cleanup**: After merge(s):
  - Ask: "Delete roll branch? (y/N)" — default no
  - If yes: `git branch -d <roll>` (safe delete, warns if not fully merged)
  - Repeat for each merged roll
- [ ] **Rolling Reintegration**: After promotion (rolling → main), rebase develop onto
  main:
  - `git checkout develop && git rebase main`
  - This keeps develop in sync and prevents long-term drift
- [ ] **Dry-Run / Preview Mode**: `--dry-run` flag that shows what WOULD happen without
  executing any destructive operations
  - This address a gap in the current tool — Lord Gig noted the lack of preview

## Implementation Checklist

### Phase 1: Design & Planning

- [ ] Define the exact user interaction flow (text-based prompts, tables)
- [ ] Design the roll selection algorithm (sort by dependency order)
- [ ] Map out all edge cases (conflicts, failed checks, partial merges)
- [ ] Write pseudocode for the merge loop

### Phase 2: Core Command Structure

- [ ] Create `def "main merge"` (or `def "main graduate"`) function
- [ ] Implement state detection (current branch, roll detection, rolling/main positions)
- [ ] Implement roll candidate gathering from `get-roll-history` output
- [ ] Integrate with existing `check-roll-verification` for status display
- [ ] Add dependency resolution and ordering

### Phase 3: Interactive Selection UI

- [ ] Build numbered roll list with verification status table
- [ ] Implement user input loop for roll selection (by number, ranges, "all")
- [ ] Add confirmation prompt with summary of what will happen
- [ ] Implement `--dry-run` mode that shows plan without executing

### Phase 4: Pre-Merge Safety Checks

- [ ] Run `nix flake check` on each selected roll branch
- [ ] Read test-all commits for verification proof
- [ ] Check target branch for unmerged dependencies
- [ ] Check for merge conflicts with target
- [ ] Report any failures and offer to abort or continue with warnings

### Phase 5: Merge Execution

- [ ] Execute `git merge --no-ff` for roll → rolling (graduation)
- [ ] Execute `git merge --no-ff` rolling → main (promotion)
- [ ] Handle merge conflicts with clear error messages
- [ ] Write structured merge commit messages

### Phase 6: Post-Merge Cleanup

- [ ] Offer branch deletion with confirmation (default: no)
- [ ] Implement safe delete (`git branch -d`, warns on unmerged)
- [ ] Execute `develop` rebase onto `main` after promotion
- [ ] Print final summary of what was done

### Phase 7: Testing & Polish

- [ ] Test with multiple rolls in dependency order
- [ ] Test dry-run mode produces accurate preview
- [ ] Test conflict detection and recovery
- [ ] Test branch delete safety
- [ ] Test develop reintegration after promotion
- [ ] Edge case: no rolls to merge
- [ ] Edge case: uncommitted changes in working tree
- [ ] Edge case: all hosts already verified vs partially verified

## Technical Notes

### 2026-05-31 — Foundation Complete

- **test-all structured commits**: `test(roll/N-theme): flake=pass host=✓ ...`
  with body sections Host-Results, Flake-Check, Scope, Changed-Files, Branch, Timestamp
- **Two-source verification**: `check-roll-verification` checks test-all commits first,
  then falls back to rolling rebuild detection
- **Stderr noise suppressed**: All git commands use `do -i { ^git ... }` pattern to
  suppress stderr without triggering parser errors
- **resolve-roll-ref fixed**: `out+err>| ignore` was resetting `LAST_EXIT_CODE` to 0;
  fixed by using `do -i { ^git ... } | complete` pattern instead
- **Scope detection working**: `detect-roll-scope` correctly identifies NixOS, Home,
  Flake, and Docs changes per roll

### Design Considerations

- The current `roll-graduate` and `roll-promote` work but are non-interactive. They
  should be replaced, not modified.
- The interactive flow should be robust against partial execution (if a merge fails
  partway through, the state should be recoverable)
- Merge commit messages should include structured data (like test-all commits) for
  future tooling to read
- The `--dry-run` mode is important for trust — users should see the plan before
  committing to it

### Dependency Resolution Algorithm

Rolls should be merged in order of dependency. A roll B depends on roll A if:
- B was branched from A (B's base commit is in A's history)
- A's files overlap with B's scope

Current `check-roll-dependencies` function already computes this. The merge flow
should present rolls in topological order (dependencies first).

## Resources & References

- Current roll-flow script: `~/local_repos/.dotfiles/scripts/roll-flow`
- Existing graduation: `def "main roll-graduate"` in roll-flow
- Existing promotion: `def "main roll-promote"` in roll-flow
- Test-all commit format: structured with `test(roll/N-theme):` header
- Verification functions: `check-roll-verification`, `check-roll-diverged`
- Fleet standards: `~/local_repos/annex/fleet/knowledge-base/standards/git/`

## Lessons Learned

[To be filled during implementation]
