# Git History Rewrite — Purge Pre-LFS Binary Blobs

**Status**: Deferred — blocked on trigger condition\
**Priority**: Low (no impact on daily workflow)\
**Estimated Scope**: 1 session + fleet-wide re-clone\
**Created**: 2026-09-18\
**Last Updated**: 2026-09-18

## Objective

Reclaim roughly 114 MB of the repository's 122 MB packfile by rewriting history to
remove large binary blobs that predate Git LFS adoption.

**This is deliberately deferred.** It does not affect day-to-day `push`/`pull` speed —
git only transfers objects the remote lacks. It affects *fresh clones*, which matter
when provisioning a new fleet host. Do not execute this opportunistically; see the
trigger condition below.

## Current State (measured 2026-09-18 on merlin)

`.git` totals **184 MB**:

| Component | Size |
|---|---|
| `.git/objects/pack` | 122 MB (4 packs, 24,677 objects) |
| `.git/lfs` | 61 MB (29 objects) |

Four blobs account for **114 MB of the 122 MB pack — ~94%**:

| Path | Raw | Packed | In HEAD? |
|---|---|---|---|
| `actualDOTFILES_MASTER/cargo.bin.tar` | 59.5 MB | 59.1 MB | No |
| `…/wallpapers/SGA/…_5K Sharper.png` | 31.2 MB | 31.2 MB | 133-byte LFS pointer |
| `…/wallpapers/SGA/…_5K.png` | 19.1 MB | 18.9 MB | 133-byte LFS pointer |
| `…/wallpapers/SGA/…_2560x1440.png` | 5.0 MB | 5.0 MB | 133-byte LFS pointer |

Stripping these would bring the pack to roughly **8 MB**.

## Why `git gc` Cannot Reclaim Them

Both causes reduce to the same thing: **the blobs are still reachable from history**,
so garbage collection will never touch them. `git gc --aggressive --prune=now` is safe
to run and will repack 4 packs into 1, but it will not shrink the repository materially.

### Cause 1 — the tarball was deleted, not purged

- `630b4284` (2024-08-22) added a 59 MB tarball of cargo binaries.
- `b16bb741` (2024-08-22) removed it, replacing it with a plain-text listing. The commit
  message confirms the intent was always to document *which* binaries were in use, not
  to archive them — so the tarball was never wanted in history.

Deleting a file in a later commit does not remove it from earlier ones. The adding
commit remains reachable, so the blob remains.

### Cause 2 — LFS was adopted after the fact

The SGA wallpapers were committed raw, and `.gitattributes` gained `*.png` tracking
later, in `9f99c2f2` (2026-01-28). **`git lfs track` only governs future commits — it
never rewrites existing history.** The result is that each image is now stored twice:

```
history:    31.2 MB raw blob        (pre-LFS commits, permanently reachable)
.git/lfs:   32 MB LFS object        (post-migration copy)
HEAD:       133-byte pointer file
```

~112 MB of disk for ~57 MB of actual images. `git lfs migrate` was the command needed at
migration time; it was not run.

## Trigger Condition — DO NOT EXECUTE BEFORE THIS

Rewriting history changes every commit SHA from the rewrite point forward. That requires
a force-push to `origin` and a re-clone on **every** fleet host.

**Execute only when roll branches are at a minimum:**

- [ ] `rolling` has been promoted to `main` (`roll-flow promote`)
- [ ] No active `roll/*` branches with unmerged work
- [ ] No active `feature/*` branches with unmerged work
- [ ] No in-flight worktrees under `./worktrees/`
- [ ] All four hosts (ganoslal, merlin, wsl, spacedock) are at a known-good generation
      and available to re-clone

For scale, as of 2026-09-18 the repo carries 7,460 commits and 46 refs
(17 local branches, 20 remote-tracking, 9 tags). Attempting this mid-roll would be
badly disruptive.

## Implementation Sketch

Not yet validated — treat as a starting point, and rehearse on a scratch clone first.

- [ ] Back up: full mirror clone to external storage, verified restorable
- [ ] Rehearse the entire procedure on the backup clone; confirm HEAD trees are byte
      identical before/after (only history should change, not the current checkout)
- [ ] Purge the tarball outright — it is wanted nowhere:
      `git filter-repo --path actualDOTFILES_MASTER/cargo.bin.tar --invert-paths`
- [ ] Convert the pre-LFS wallpaper blobs to pointers:
      `git lfs migrate import --above=1MB --everything`
      (verify it does not double-convert paths already in LFS)
- [ ] Confirm `git count-objects -vH` shows the expected drop
- [ ] Confirm `git lfs ls-files` still lists all 28–29 tracked files
- [ ] Force-push all refs and tags
- [ ] Re-clone on each host; verify `just check` and a rebuild on each

### Fleet re-clone checklist

- [ ] ganoslal
- [ ] merlin
- [ ] wsl (remember: flake target is `wsl`, not the hostname `nixos`)
- [ ] spacedock

## Technical Notes

- HEAD is already clean — the working tree holds only 133-byte LFS pointers. This is
  purely historical weight.
- `.gitattributes` currently tracks `*.png`, `*.jpg`, `*.jpeg`, `*.webp`, `*.tar`,
  `*.pdf`, `*.tar.gz` via LFS, with `*.csv` and `*.log` explicitly *excluded*
  (`!filter !merge !diff`). Any rewrite must preserve that exclusion.
- Unrelated cleanup, safe to do any time: `git remote remove mirror` — it points at
  `/tmp/dotfiles-sanitize.git`, which does not exist, and carries a stale LFS endpoint.

## Resources & References

- `roll-flow` (aka `rf`, external package, provided in the devShell) — `roll-flow status`,
  `roll-flow graduate`, `roll-flow promote`. Note: CLAUDE.md still documents these as
  `just roll-*` recipes and references `docs/guides/ROLL-FLOW-QUICKREF.md`; neither
  exists in this repo as of 2026-09-18.
- `git-filter-repo`: https://github.com/newren/git-filter-repo
- `git lfs migrate`: https://github.com/git-lfs/git-lfs/blob/main/docs/man/git-lfs-migrate.adoc
