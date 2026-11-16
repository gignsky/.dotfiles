# spaceweed -- sync-safe wrapper around the Spaceweed Inc. coop ledger TUI.
#
#   1. pulls the annex fresh (rebase, autostash) so you edit the latest books
#   2. runs the real spaceweed against the annex's ledger
#   3. commits the ledger (--no-verify, skipping pre-commit) and pushes it
#
# Step 3 also runs if the session is killed (terminal closed, etc.).
# Passing --ledger, -h/--help or -V/--version skips all syncing.
#
# Injected by the Nix wrapper: SPACEWEED_BIN (the real binary).
# Overridable: SPACEWEED_ANNEX (default ~/local_repos/annex).

annex="${SPACEWEED_ANNEX:-$HOME/local_repos/annex}"
ledger_dir="Spaceweed Inc"

say() { printf '\033[1;32m[spaceweed]\033[0m %s\n' "$*" >&2; }
warn() { printf '\033[1;33m[spaceweed]\033[0m %s\n' "$*" >&2; }

# Pass straight through for anything that isn't a session on the annex ledger.
for arg in "$@"; do
  case "$arg" in
    -l | --ledger | -h | --help | -V | --version) exec "$SPACEWEED_BIN" "$@" ;;
  esac
done

if [[ ! -d "$annex/.git" ]]; then
  warn "annex not found at $annex (set SPACEWEED_ANNEX to override)"
  exit 1
fi
cd "$annex" || exit 1

# ---- 1. pull fresh --------------------------------------------------------
say "pulling annex..."
if ! git pull --rebase --autostash --quiet; then
  git rebase --abort >/dev/null 2>&1 || true
  warn "could not pull the annex -- the ledger may be stale."
  read -r -p "Open it anyway? [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]] || exit 1
fi

# ---- 3. commit + push (on any exit from here on) --------------------------
synced=0
sync_out() {
  ((synced)) && return
  synced=1
  cd "$annex" || return

  git add -A -- "$ledger_dir"
  if ! git diff --cached --quiet -- "$ledger_dir"; then
    # pathspec on commit keeps anything else you had staged out of this commit
    git commit --no-verify --quiet \
      -m "spaceweed: ledger update $(date '+%Y-%m-%d %H:%M') ($(hostname))" \
      -- "$ledger_dir" &&
      say "committed ledger changes"
  else
    say "no ledger changes"
  fi

  # Push whenever we're ahead -- this also retries a push that failed last time.
  # Hooks stay on for the push: the annex's pre-push uploads Git LFS objects.
  if [[ -n "$(git rev-list '@{u}..HEAD' 2>/dev/null)" ]]; then
    say "pushing..."
    if git push --quiet || { git pull --rebase --autostash --quiet && git push --quiet; }; then
      say "pushed to $(git rev-parse --abbrev-ref '@{u}')"
    else
      git rebase --abort >/dev/null 2>&1 || true
      warn "PUSH FAILED -- your ledger is committed locally but not on origin."
      warn "fix it in $annex, or just run spaceweed again to retry."
      return 1
    fi
  fi
}
trap sync_out EXIT
trap 'exit 129' HUP
trap 'exit 143' TERM

# ---- 2. run ---------------------------------------------------------------
export SPACEWEED_LEDGER="$annex/$ledger_dir/ledger.toml"
status=0
"$SPACEWEED_BIN" "$@" || status=$?
sync_out || status=1
exit "$status"
