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

# Embedded Scotty logging functions for nix environment compatibility
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
        echo "date,host,operation,duration_seconds,success,error_type,git_commit,git_branch,git_status,flake_lock_hash,generation_number,notes" > "$csv_file"
    fi
    
    # Append the data
    echo "${timestamp},${host},${operation},${duration_seconds},${success},${error_type},${git_commit},${git_branch},${git_status},${flake_lock_hash},${generation_number},${notes}" >> "$csv_file"
}

failable-pre-commit() {
  nix develop -c pre-commit run --all-files
}

set -e
pushd . || exit

# Log build start
start_time=$(date +%s)

git diff -U0 ./*glob*.nix
echo "Running pre-commit on all files"
failable-pre-commit || true
echo "Home-Manager Rebuilding..."

# Capture build success/failure
if home-manager switch -b backup --flake .#gig@"$HOST"; then
  # Get the generation number after successful build
  gen=$(home-manager generations 2>/dev/null | head -n 1)
  generation_number=$(echo "$gen" | grep -o 'generation [0-9]*' | grep -o '[0-9]*' || echo "unknown")
  
  # Calculate build duration
  end_time=$(date +%s)
  duration=$((end_time - start_time))
  
  # Log successful build
  log_build_performance "home-manager-rebuild-${HOST}" "$duration" "true" "" "Automated home-manager rebuild with Scotty logging" "$generation_number"
  
  # Commit with generation info
  git commit -a --allow-empty -m "gig@$HOST: $gen" || true
  
  echo "✅ Home Manager rebuild successful! Generation: $generation_number (${duration}s)"
else
  end_time=$(date +%s)
  duration=$((end_time - start_time))
  
  # Log failed build
  log_build_performance "home-manager-rebuild-${HOST}" "$duration" "false" "home-manager-switch-failed" "Build failed during switch operation" "unknown"
  
  echo "❌ Home Manager rebuild failed!"
  exit 1
fi

popd || exit
