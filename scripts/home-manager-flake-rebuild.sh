#!/usr/bin/env bash

# Source Scotty's logging library for automatic build logging
source "$(dirname "$0")/scotty-logging-lib.sh"

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

failable-pre-commit() {
  nix develop -c pre-commit run --all-files
}

set -e
pushd . || exit

# Log build start
start_time=$(date +%s)
scotty_log_event "build-start" "home-manager-rebuild-${HOST}"

git diff -U0 ./*glob*.nix
echo "Running pre-commit on all files"
failable-pre-commit || true
echo "Home-Manager Rebuilding..."

# Capture build success/failure
if home-manager switch -b backup --flake .#gig@"$HOST"; then
  build_success="true"
  # Get the generation number after successful build
  gen=$(home-manager generations 2>/dev/null | head -n 1)
  generation_number=$(echo "$gen" | grep -o 'generation [0-9]*' | grep -o '[0-9]*' || echo "unknown")
  
  # Calculate build duration
  end_time=$(date +%s)
  duration=$((end_time - start_time))
  
  # Log successful build
  scotty_log_event "build-complete" "home-manager-rebuild-${HOST}" "$duration" "$build_success" "$generation_number"
  
  # Commit with generation info
  git commit -a --allow-empty -m "gig@$HOST: $gen" || true
else
  build_success="false"
  end_time=$(date +%s)
  duration=$((end_time - start_time))
  
  # Log failed build
  scotty_log_event "build-error" "home-manager-rebuild-${HOST}" "Home Manager rebuild failed"
  log_build_performance "home-manager-rebuild-${HOST}" "$duration" "false" "home-manager-switch-failed" "Build failed during switch operation" "unknown"
  
  echo "Home Manager rebuild failed!"
  exit 1
fi

popd || exit
