# Documentation Migration Notice

**Date**: 2026-02-03  
**Action**: Documentation, logs, and operational records migrated to Annex repository

---

## What Was Migrated

The following content has been migrated from this repository (`~/.dotfiles`) to the Annex repository (`~/local_repos/annex`):

- **Documentation** (`docs/`)
  - Technical guides → `annex/fleet/knowledge-base/technical/`
  - Standards → `annex/fleet/knowledge-base/standards/`
  - Creative works → `annex/captains-files/creative/`
  - Planning docs → `annex/fleet/operations/planning/`

- **Operations** (`operations/`)
  - Fleet management → `annex/fleet/operations/management/`
  - Reports → `annex/fleet/operations/reports/`
  - Logs → `annex/crew-logs/scotty/engineering-logs/YYYY-MM/` (verified duplicate of scottys-journal logs)
  - **Note**: CSV metrics files were NOT migrated (narrative logs serve as primary source)

- **Scotty's Logs** (`scottys-journal/`)
  - Engineering logs (93 files) → `annex/crew-logs/scotty/engineering-logs/YYYY-MM/`
  - Command logs → `annex/crew-logs/scotty/command-logs/`
  - Snapshots → `annex/crew-logs/scotty/snapshots/`

- **Archives** (`archives/`)
  - Reference materials → `annex/fleet/archives/reference/`

- **Personal Files**
  - `notes.md` → `annex/captains-files/notes.md`

## What Remains Here

This repository (`~/.dotfiles`) still contains:
- Configuration files (home-manager, NixOS, etc.)
- Scripts and automation
- Temporary logs (`.tmp-oc-logs/`)
- Agent personality files
- Active operational files (except those migrated)

## Finding Migrated Content

**Quick Reference**:
- Path mapping: `~/local_repos/annex/PATH-CHANGES.md`
- Directory index: `~/local_repos/annex/DIRECTORY-INDEX.md`
- Migration details: `~/local_repos/annex/MIGRATION-NOTES.md`

**Common Lookups**:
- Technical docs: `annex/fleet/knowledge-base/technical/`
- Git conventions: `annex/fleet/knowledge-base/standards/git/`
- Engineering logs: `annex/crew-logs/scotty/engineering-logs/YYYY-MM/`
- Fleet operations: `annex/fleet/operations/management/`
- Personal notes: `annex/captains-files/notes.md`

## Migration Method

**All files were COPIED (not moved)**. Original files remain in this repository until cleanup phase decision.

---

**See Annex repository for complete documentation and operational records.**

Library Computer, U.S.S. Annex (NCC-0001)
