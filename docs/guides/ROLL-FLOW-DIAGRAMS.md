# Roll Flow Visual Guide

## Branch Hierarchy Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         MAIN BRANCH                              │
│              Verified stable for ALL hosts                       │
│  ├─ tag: stable-20260527                                        │
│  ├─ tag: stable-20260530                                        │
│  └─ tag: stable-20260602 ←── (only promotion from rolling)     │
└─────────────────────────────────────────────────────────────────┘
                              ▲
                              │ just roll-promote
                              │ (after testing ALL hosts)
┌─────────────────────────────────────────────────────────────────┐
│                      ROLLING BRANCH                              │
│         Integration branch (like nixos-unstable)                 │
│  ├─ Merge from roll/4                                           │
│  ├─ Merge from roll/5                                           │
│  └─ Merge from roll/6 ←── (just roll-graduate)                 │
└─────────────────────────────────────────────────────────────────┘
                              ▲
                              │ Graduates from roll/* branches
                              │ (tested on SOME hosts)
          ┌───────────────────┴───────────────────┐
          │                                       │
┌─────────────────────────┐         ┌─────────────────────────┐
│   roll/5-0530-shell     │         │  roll/6-0601-displays   │
│   (shell improvements)  │         │  (display config work)  │
│  ├─ feature/zellij      │         │  ├─ feature/ganoslal-   │
│  ├─ feature/starship    │         │  │    monitors          │
│  └─ fix/nushell-prompt  │         │  └─ fix/merlin-outdoor  │
└─────────────────────────┘         └─────────────────────────┘
          ▲                                       ▲
          │ just roll-integrate                   │
          │                                       │
┌─────────────────────┐               ┌─────────────────────┐
│ feature/zellij-     │               │ feature/ganoslal-   │
│   config            │               │   monitors          │
│ (individual work)   │               │ (individual work)   │
└─────────────────────┘               └─────────────────────┘
```

## Workflow State Machine

```
┌──────────────┐
│ Start Work   │
└──────┬───────┘
       │
       │ just roll-start <theme>
       ▼
┌──────────────────────────────────────────────────────────┐
│ Roll Created: roll/N-MMDD-<theme>                        │
│ Status: Active                                           │
│ Merged Features: []                                      │
└──────┬───────────────────────────────────────────────────┘
       │
       │ Create feature branches
       │ git checkout -b feature/xyz
       ▼
┌──────────────────────────────────────────────────────────┐
│ Feature Development                                      │
│ - Make changes                                           │
│ - Test with: just rebuild                               │
│ - Commit frequently                                      │
└──────┬───────────────────────────────────────────────────┘
       │
       │ just roll-integrate feature/xyz
       ▼
┌──────────────────────────────────────────────────────────┐
│ Roll Updated                                             │
│ Status: Active                                           │
│ Merged Features: [feature/xyz]                          │
│                                                          │
│ ◄──────── Repeat integration until roll complete        │
└──────┬───────────────────────────────────────────────────┘
       │
       │ just roll-graduate
       │ (tested on at least one host)
       ▼
┌──────────────────────────────────────────────────────────┐
│ Roll Graduated to Rolling                                │
│ Status: Graduated                                        │
│ Available for testing on other hosts                     │
└──────┬───────────────────────────────────────────────────┘
       │
       │ Test on all hosts:
       │ - ganoslal: git checkout rolling && just rebuild
       │ - merlin: git checkout rolling && just rebuild
       │ - wsl: git checkout rolling && just rebuild
       ▼
┌──────────────────────────────────────────────────────────┐
│ Fix Issues if Needed                                     │
│ - Create fix branches from rolling                       │
│ - Merge fixes directly to rolling                        │
│ - Retest all hosts                                       │
└──────┬───────────────────────────────────────────────────┘
       │
       │ just roll-promote
       │ (all hosts verified)
       ▼
┌──────────────────────────────────────────────────────────┐
│ Promoted to Main                                         │
│ - Tagged with date: stable-YYYYMMDD                      │
│ - Stable for all hosts                                   │
│ - Production ready                                       │
└──────────────────────────────────────────────────────────┘
```

## Timeline Example: A Week of Development

```
Mon     Tue          Wed          Thu          Fri
│       │            │            │            │
│ Start │            │            │ Graduate   │ Promote
│ Roll 5│ Integrate  │ Integrate  │ Roll 5     │ to Main
│       │ zellij     │ starship   │ to Rolling │
│       │            │            │            │
├───────┼────────────┼────────────┼────────────┼────────────
│       │            │            │            │
│ [5]   │ [5]        │ [5]        │ rolling    │ main
│       │  +zellij   │  +starship │  ←roll/5   │  ←rolling
│       │            │            │            │  tag: stable
│       │            │            │ Start      │
│       │            │            │ Roll 6     │
│       │            │            │            │
│       │            │            │ [6]        │
│       │            │            │            │

Legend:
[N] = Active roll number
+feature = Feature integrated
←roll = Merge direction
```

## Multi-Host Testing Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                  ROLLING BRANCH (Central Hub)                    │
└───┬────────────────────┬────────────────────┬────────────────────┘
    │                    │                    │
    │ git pull           │ git pull           │ git pull
    │ just rebuild       │ just rebuild       │ just rebuild
    ▼                    ▼                    ▼
┌─────────┐          ┌─────────┐          ┌─────────┐
│ Ganoslal│          │ Merlin  │          │   WSL   │
│         │          │         │          │         │
│ ✅ OK   │          │ ❌ Issue│          │ ✅ OK   │
└─────────┘          └────┬────┘          └─────────┘
                          │
                          │ Create fix branch
                          ▼
                    ┌──────────────┐
                    │ fix/merlin-  │
                    │   display    │
                    └──────┬───────┘
                           │
                           │ Merge to rolling
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│              ROLLING BRANCH (Updated with Fix)                   │
└───┬────────────────────┬────────────────────┬────────────────────┘
    │                    │                    │
    │ Retest             │ Retest             │ Retest
    ▼                    ▼                    ▼
┌─────────┐          ┌─────────┐          ┌─────────┐
│ ✅ OK   │          │ ✅ Fixed│          │ ✅ OK   │
└─────────┘          └─────────┘          └─────────┘
                           │
                           │ All hosts verified!
                           ▼
                    ┌──────────────┐
                    │ just roll-   │
                    │   promote    │
                    └──────┬───────┘
                           │
                           ▼
                    ┌──────────────┐
                    │ MAIN BRANCH  │
                    │ (Stable)     │
                    └──────────────┘
```

## Parallel Work with Worktrees

```
Main Repository: ~/.dotfiles
├── .git/
├── hosts/
├── home/
└── worktrees/
    ├── shell-work/         (roll/5-0530-shell)
    │   └── [Isolated workspace for shell improvements]
    │
    └── display-work/       (roll/6-0530-displays)
        └── [Isolated workspace for display config]

Work simultaneously:
Terminal 1: cd ~/.dotfiles/worktrees/shell-work
           just rebuild (tests shell changes)

Terminal 2: cd ~/.dotfiles/worktrees/display-work
           just rebuild (tests display changes)

Both can be tested independently without affecting main repo!
```

## Roll Lifecycle States

```
                    ┌─────────────┐
                    │   PLANNED   │
                    │ (not created│
                    │     yet)    │
                    └──────┬──────┘
                           │
                    just roll-start
                           │
                           ▼
    ┌──────────────────────────────────────────┐
    │              ACTIVE                      │
    │  - Currently being worked on             │
    │  - Accepting feature integrations        │
    │  - Testing in progress                   │
    └──────┬───────────────────────────────────┘
           │
    just roll-graduate
           │
           ▼
    ┌──────────────────────────────────────────┐
    │           GRADUATED                      │
    │  - Merged to rolling branch              │
    │  - Available for wider testing           │
    │  - Branch kept for reference             │
    └──────┬───────────────────────────────────┘
           │
    just roll-promote (from rolling)
           │
           ▼
    ┌──────────────────────────────────────────┐
    │            STABLE                        │
    │  - Merged to main                        │
    │  - Tagged with date                      │
    │  - Verified on all hosts                 │
    │  - Production ready                      │
    └──────────────────────────────────────────┘
           │
    (Optional: Archive old roll branches)
           │
           ▼
    ┌──────────────────────────────────────────┐
    │           ARCHIVED                       │
    │  - Branch deleted (merged into main)     │
    │  - History preserved in main branch      │
    │  - Documented in git tags                │
    └──────────────────────────────────────────┘
```

---

*"A picture's worth a thousand words, but a good git diagram? That's worth a thousand debug sessions!"*  
— Chief Engineer Montgomery Scott, Stardate 2026-05-30
