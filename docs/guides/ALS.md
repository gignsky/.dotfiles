# `als` — alias finder for Nushell

`als` does two things:

1. **Lookup** — find an alias by name, or find the aliases for a command you typed.
2. **Hint** — a `pre_execution` hook that shows a box when you type the long form of
   something you have an alias for.

This restores, on Nushell, what the zsh setup still gets from the
`akash329d/zsh-alias-finder` and oh-my-zsh `aliases` plugins
(`home/gig/common/core/zsh.nix`). zsh needs no changes; this is Nushell-only.

## Usage

| Command | What it does |
|---|---|
| `als` | list every alias (243 currently) |
| `als gl` | forward lookup — `gl -> git pull` |
| `als git log` | reverse lookup — see below |
| `als stats` | keystrokes saved / missed on this machine |
| `als stats --json` | same as a record, with a `hostname` field |
| `als stats --fleet` | aggregate across ssh hosts |
| `als hint <line>` | render the hint box for a line (what the hook calls) |
| `als reindex` | rebuild the cached index after a runtime `overlay use` |

### Reverse lookup shows two sections

There is no alias for plain `git log` — in the oh-my-zsh convention `gl` is `git pull`.
So `als git log` reports both directions:

```
shorter — you could type this instead
  g  ->  git  (saves 2)

related — aliases that start with this
  glg    ->  git log --stat
  glo    ->  git log --oneline --decorate
  glog   ->  git log --oneline --decorate --graph
  ...
```

`shorter` is what the hint would say. `related` is the discovery half, and it is the
reason `als git log` is worth typing.

### The hint

Typing `nix run nixpkgs#hello` prints, above the command's output:

```
╭─ alias ──────────────╮
│  nr  ->  nix run     │
│  saves 5 keystrokes  │
╰──────────────────────╯
```

Policy: the **longest** matching alias wins, and only if it is strictly shorter than what
you typed. Typing the alias itself never hints. Ties break deterministically
(most words, then most saved, then alphabetical) — `sort-by --reverse` is *not* stable for
ties, so this is done explicitly.

Measured on ~9,700 lines of real history, the hint fires on about **3%** of commands.

## Configuration

All optional, all via `$env`, so the module itself is host-agnostic:

| Variable | Default | Meaning |
|---|---|---|
| `$env.ALS_HINT` | `true` | set false to disable the hint box |
| `$env.ALS_MIN_SAVED` | `1` | minimum keystrokes saved before hinting |
| `$env.ALS_IGNORE` | `[]` | alias names never hinted |
| `$env.ALS_FLEET` | injected | `[{name, target, remote?, enabled?}]` for `--fleet` |

`ALS_FLEET` is generated in `home/gig/common/core/nushell.nix` from two files:
`vars/fleet.nix` (how to reach a host) and `vars/hosts.nix` (whether it is active).
Splitting them means taking a host offline is a one-line change in `hosts.nix`.

## Architecture

### Why a `.nu` module and not a Nushell plugin

Both features need `scope aliases`, which only exists **inside** the running engine.
Nushell plugins run out-of-process, and the plugin API (`EngineInterface`) exposes
`get_config`, `get_env_var`, `eval_closure`, `find_decl`, `call_decl` — but **no alias
enumeration**. So a binary on `PATH` cannot implement this, and the nixpkgs
`nushellPlugins.*` slot is not reachable without solving that first.

The unit of distribution is therefore a `.nu` file.

### Where the aliases come from

Two scopes, both read at runtime — never parsed out of Nix:

- `programs.nushell.shellAliases` → 51 `alias "name" = body` lines, emitted at the **end**
  of `config.nu`
- `overlay use ${inputs.git-aliases}/git-aliases.nu` → 192 `export alias` lines

`scope aliases` sees both, including from inside a hook closure (verified).

### Why the hint builds no index

Building the full index costs **~37ms**. Paying that on every command is perceptible, and
caching it in `$env` from a hook is fragile. Instead `als hint` filters `scope aliases`
down to the few candidates sharing a first word, which costs **~1–4ms** and needs no cache
at all. The full index is still used by `als stats` and `als <query>`, where a one-off 37ms
does not matter.

This also sidesteps an ordering trap: `extraConfig` is emitted *before* the shellAliases
block, so anything eager at config-load time would only see the 192 overlay aliases.

## Gotchas discovered while building this

- **A shellAlias shadows a `def` of the same name.** Home Manager emits aliases last, so
  `als = "help aliases"` had to be removed from `shellAliases.nix` or the module would be
  silently dead. `which als` should report `custom`, not `alias`.
- **`str length` counts UTF-8 bytes.** `"─" | str length` is 3. Box padding and keystroke
  counts use `--grapheme-clusters`.
- **ANSI codes inflate width.** A single colored character measures 10 raw vs 1 stripped;
  box widths are measured after `ansi strip`.
- **`sort-by --reverse` is not stable for ties** — hence the explicit tie-break.
- **`mut list | append` in a loop is O(n²).** The history scan took 7.8s that way and 2.7s
  built with `each`.
- **`nu -c` does not load config; `nu -l -c` does.** `nu -c 'scope aliases | length'`
  returns 0. This is why the `--fleet` remote command uses `-l`.
- **`export def` at the top level of an inlined file works fine** and binds into the current
  scope, so the same file works both inlined and as `use als.nu *`.

## Upstream path

The module is written with no dotfiles-specific hardcoding so that each rung is a move
rather than a rewrite.

1. **In-repo** (where it is now) — `home/gig/common/resources/nushell/als.nu`, auto-inlined
   by `lib.scanPathsNuShell`. Fast edit loop: change the file, `just home`.
2. **Standalone repo** — `gignsky/nu-als` with `flake = false`, consumed via
   `overlay use ${inputs.nu-als}/als.nu`, exactly like the existing `git-aliases.nu` wiring.
3. **`nushell/nu_scripts` PR** — this is the realistic route into nixpkgs. `nu_scripts` is
   already a nixpkgs package, so a module merged there ships without creating a new package.
4. **`nushellPlugins.als`** — a real Rust plugin, only if the scope-access problem above can
   be solved. Worth a spike on whether `find_decl`/`call_decl` can reach `scope aliases`
   from a plugin; record the answer here either way.

### Extraction checklist

- [ ] `als.nu` references no path under `~/.dotfiles` and no host names — all such data
      arrives via `$env.ALS_*`.
- [ ] Verify standalone use: `nu -n -c 'use als.nu *; als box "t" ["a"]'`.
- [ ] Move `vars/fleet.nix` consumption into the consumer, not the module.
- [ ] Keep the `$env.ALS_*` contract documented in the module header.

## Phase 2 (not done): sqlite history

`als stats` reads through the `history` **command**, not the history file, so it works
unchanged on either backend. Plaintext yields `{command, index}`; sqlite yields
`{item_id, start_timestamp, command, session_id, hostname, cwd, duration, exit_status}`.

Switching would unlock savings-over-time, which plaintext cannot provide (it has no
timestamps). To do it:

- set `programs.nushell.settings.history.file_format = "sqlite"`, migrate with
  `history import`
- note: imported plaintext rows arrive with `start_timestamp`, `hostname` and `cwd` all
  **null**, so lifetime totals stay retroactive but any trend line starts at switchover
- it is reversible — `history import` runs in both directions
- roll out on one host first
