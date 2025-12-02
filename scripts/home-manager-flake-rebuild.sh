#!/usr/bin/env bash

if [ -n "$1" ]; then
  export HOST="$1"
else
  if [ "$(hostname)" = "nixos" ]; then
    HOST="wsl"
  else
    HOST="$(hostname)"
  fi
  export HOST
fi

# Source Scotty's logging library for automatic build logging
# Try multiple locations for the logging library
LOGGING_LIB_PATHS=(
  "${SCOTTY_LOGGING_LIB_PATH:-}"
  "${HOME}/.dotfiles/scripts/scotty-logging-lib.sh"
  "$(dirname "$0")/scotty-logging-lib.sh"
)

LOGGING_LIB_FOUND=false
for lib_path in "${LOGGING_LIB_PATHS[@]}"; do
  if [ -n "$lib_path" ] && [ -f "$lib_path" ]; then
    source "$lib_path"
    LOGGING_LIB_FOUND=true
    break
  fi
done

if [ "$LOGGING_LIB_FOUND" = false ]; then
  # Fallback: define basic logging functions if library is not found
  scotty_log_event() { echo "[$1] $*" >&2; }
  log_build_performance() {
    local operation="$1"
    local duration_seconds="$2"
    local success="$3"
    local error_type="$4"
    local notes="$5"
    local generation_number="${6:-unknown}"

    local journal_dir="${HOME}/.dotfiles/worktrees/main/scottys-journal"
    local metrics_dir="${journal_dir}/metrics"
    mkdir -p "$metrics_dir"

    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local host
    host=$(hostname)

    # Get git state
    local git_commit
    git_commit=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
    local git_branch
    git_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
    local git_status="clean"
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
      local modified_count
      modified_count=$(git status --porcelain | wc -l)
      git_status="${modified_count}_modified"
    fi
    local flake_lock_hash="none"
    if [ -f "flake.lock" ]; then
      flake_lock_hash=$(sha256sum flake.lock | cut -d' ' -f1)
    fi

    local csv_file="${metrics_dir}/build-performance.csv"

    # Create header if file doesn't exist
    if [ ! -f "$csv_file" ]; then
      echo "date,host,operation,duration_seconds,success,error_type,git_commit,git_branch,git_status,flake_lock_hash,generation_number,notes" >"$csv_file"
    fi

    # Append the data
    echo "${timestamp},${host},${operation},${duration_seconds},${success},${error_type},${git_commit},${git_branch},${git_status},${flake_lock_hash},${generation_number},${notes}" >>"$csv_file"
  }
fi

failable-pre-commit() {
  @nix develop -c echo '*The Pre-Commit has been given a chance to Update!*'
  nix shell nixpkgs#pre-commit -c pre-commit run --all-files
}

set -e
pushd . || exit

# Log build start
start_time=$(date +%s)

# Capture previous generation for comparison
previous_gen=$(home-manager generations 2>/dev/null | head -n 1 | grep -o 'id [0-9]*' | grep -o '[0-9]*' || echo "0")

# Find the last home-manager rebuild commit for this host
echo "=== ANALYZING CONFIGURATION CHANGES SINCE LAST REBUILD ==="
last_rebuild_commit=$(git log --oneline --grep="gig@${HOST}:" -1 --format="%H" 2>/dev/null || echo "")

if [ -n "$last_rebuild_commit" ]; then
  echo "Last rebuild commit for ${HOST}: ${last_rebuild_commit}"
  config_files_changed=$(git diff --name-only "${last_rebuild_commit}..HEAD" | grep -E '\.(nix|conf|toml|yaml|yml)$' || echo "")
  if [ -n "$config_files_changed" ]; then
    echo "Configuration files changed since last rebuild:"
    echo "$config_files_changed"
    # Capture detailed diff for Scotty (limited to avoid huge output)
    detailed_diff=$(git diff "${last_rebuild_commit}..HEAD" -- "*.nix" "*.conf" "*.toml" "*.yaml" "*.yml" | head -200)
  else
    config_files_changed="No configuration files changed"
    detailed_diff="No configuration changes detected"
  fi
else
  echo "No previous rebuild found for ${HOST} - this appears to be the first rebuild"
  config_files_changed="First rebuild for this host"
  detailed_diff="Initial configuration deployment for ${HOST}"
fi

git diff -U0 ./*glob*.nix
echo "Running pre-commit on all files"
failable-pre-commit || true
echo "Home-Manager Rebuilding..."

# Capture build success/failure
if home-manager switch -b backup --flake .#gig@"$HOST"; then
  # Get the generation number after successful build
  gen=$(home-manager generations 2>/dev/null | head -n 1)
  generation_number=$(echo "$gen" | grep -o 'id [0-9]*' | grep -o '[0-9]*' || echo "unknown")

  # Calculate build duration
  end_time=$(date +%s)
  duration=$((end_time - start_time))

  # Log successful build to CSV
  log_build_performance "home-manager-rebuild-${HOST}" "$duration" "true" "" "Automated home-manager rebuild with Scotty engineering logs" "$generation_number"

  # Call Scotty to create detailed engineering log
  echo "=== CALLING SCOTTY FOR DETAILED ENGINEERING LOG ==="
  if command -v opencode >/dev/null 2>&1; then
    opencode run --agent scotty "Scotty, document this successful home-manager rebuild for ${HOST}: Generation ${previous_gen} → ${generation_number}, build duration ${duration} seconds. Configuration changes since last rebuild: ${config_files_changed}. Files changed: ${detailed_diff}" || echo "Scotty logging failed, continuing..."
  else
    echo "OpenCode not available - skipping detailed Scotty log"
  fi

  # Commit with generation info
  git commit -a --allow-empty -m "gig@$HOST: $gen" || true

  echo "✅ Home Manager rebuild successful! Generation: $generation_number (${duration}s)"
  echo "📝 Detailed engineering log created by Scotty"
else
  end_time=$(date +%s)
  duration=$((end_time - start_time))

  # Log failed build to CSV
  log_build_performance "home-manager-rebuild-${HOST}" "$duration" "false" "home-manager-switch-failed" "Build failed during switch operation" "unknown"

  # Call Scotty to document the failure
  echo "=== CALLING SCOTTY FOR FAILURE ANALYSIS ==="
  if command -v opencode >/dev/null 2>&1; then
    opencode run --agent scotty "Scotty, document this FAILED home-manager rebuild for ${HOST}: Build duration ${duration} seconds, previous generation ${previous_gen}. Configuration changes attempted: ${config_files_changed}. Analyze what went wrong and provide troubleshooting recommendations." || echo "Scotty logging failed"
  else
    echo "OpenCode not available - skipping detailed Scotty failure log"
  fi

  echo "❌ Home Manager rebuild failed!"
  exit 1
fi

echo "=== CALLING SCOTTY FIX LOGS (IF NEEDED) ==="
if command -v opencode >/dev/null 2>&1; then
  opencode run --agent scotty "Scotty, could you please /fix-logs on this ${HOST}? Generation ${previous_gen} → ${generation_number}, build duration ${duration} seconds. Configuration changes since last rebuild: ${config_files_changed}. Files changed: ${detailed_diff}" || echo "Scotty logging failed, continuing..."
else
  echo "OpenCode not available - skipping detailed Scotty log-fix :("
fi

popd || exit
