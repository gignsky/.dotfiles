# System Enhancement Protocols (SEP)

This directory contains **System Enhancement Protocols** - structured documentation for planning, implementing, and tracking feature development projects.

## Purpose

SEPs provide a systematic approach to:
- Plan new features and enhancements
- Track implementation progress with checkboxes
- Document technical decisions and discoveries
- Maintain project continuity across sessions
- Enable knowledge transfer between engineers

## SEP Structure

Each SEP follows a standardized format:
- **Objective**: Clear statement of what we want to achieve and why
- **Current Plan**: High-level roadmap with strikethrough for completed/changed items
- **Technical Requirements**: Specific technical needs and constraints
- **Implementation Checklist**: Detailed task breakdown with checkboxes
- **Technical Notes**: Ongoing discoveries, issues, and solutions
- **Resources & References**: Links, documentation, and examples

## File Naming Convention

SEPs should be named descriptively:
- `001-bspwm-visual-enhancements.md`
- `002-audio-system-overhaul.md` 
- `003-network-automation-framework.md`

## Usage Protocol

1. **Planning Phase**: Create new SEP with objectives and initial plan
2. **Implementation**: Update checkboxes and notes as work progresses
3. **Documentation**: Record technical discoveries and decisions
4. **Completion**: Mark final status and archive lessons learned

## Template

Use the `template.md` file as a starting point for new SEPs.

## Index

| SEP | Status | Notes |
|---|---|---|
| `001-bspwm-visual-enhancements.md` | — | |
| `002-interactive-roll-mgmt.md` | Planning | |
| `003-git-history-rewrite.md` | **Deferred — blocked** | ⚠️ Check before every `rolling` → `main` promotion. Purges ~114 MB of pre-LFS binary blobs; requires a force-push and a fleet-wide re-clone, so it may only run when no `roll/*` or `feature/*` work is outstanding. |
| `SEP-spacedock-onboarding.md` | In progress | |
