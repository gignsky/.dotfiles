#!/usr/bin/env bash

# Initialize summary arrays at the very top so they are always available
installed=()
skipped_already_installed=()
skipped_not_found=()
failed=()
removed_exts=()
updated_exts=()

print_summary() {
  printf '\n\033[1;35m==============================\033[0m\n'
  printf '\033[1;35m✨ VS Code Extension Installation Summary ✨\033[0m\n'
  printf '\033[1;35m==============================\033[0m\n\n'
  if [ ${#installed[@]} -gt 0 ]; then
    printf '\033[1;32m✅ Installed:\033[0m\n'
    for ext in "${installed[@]}"; do
      printf '  \033[1;32m✔️ %s\033[0m\n' "$ext"
    done
    printf '\n'
  fi
  if [ ${#updated_exts[@]} -gt 0 ]; then
    printf '\033[1;34m⬆️  Updated (new version installed):\033[0m\n'
    for ext in "${updated_exts[@]}"; do
      printf '  \033[1;34m⬆️  %s\033[0m\n' "$ext"
    done
    printf '\n'
  fi
  if [ ${#skipped_already_installed[@]} -gt 0 ]; then
    printf '\033[1;36m⏭️  Skipped (already installed and up-to-date):\033[0m\n'
    for ext in "${skipped_already_installed[@]}"; do
      printf '  \033[1;36m⏭️  %s\033[0m\n' "$ext"
    done
    printf '\n'
  fi
  if [ ${#skipped_not_found[@]} -gt 0 ]; then
    printf '\033[1;33m❓ Skipped (not found or could not be installed):\033[0m\n'
    for ext in "${skipped_not_found[@]}"; do
      printf '  \033[1;33m❓ %s\033[0m\n' "$ext"
    done
    printf '\n'
  fi
  if [ ${#removed_exts[@]} -gt 0 ]; then
    printf '\033[1;31m🗑️  Removed (not in declarative list):\033[0m\n'
    for ext in "${removed_exts[@]}"; do
      printf '  \033[1;31m🗑️  %s\033[0m\n' "$ext"
    done
    printf '\n'
  fi
  if [ ${#failed[@]} -gt 0 ]; then
    printf '\033[1;31m❌ Failed:\033[0m\n'
    for ext in "${failed[@]}"; do
      printf '  \033[1;31m✖️ %s\033[0m\n' "$ext"
    done
    printf '\n'
  fi
  printf '\033[1;35m==============================\033[0m\n'
}

trap print_summary EXIT

set +e  # Use manual error handling throughout the script

# Install VS Code extensions from a JSON file (for WSL)
# Usage: ./install-vscode-extensions-wsl.sh /path/to/extensions.json

# set -euo pipefail  # Removed to avoid conflict with set +e

DEBUG=1
function debug() { echo -e "[DEBUG] $@"; }

export PATH="/bin:/usr/bin:$PATH"

debug "VSCode extension install script started at $(date)"
debug "Script started."
debug "PATH: $PATH"
debug "User: $(whoami)"
debug "Current directory: $(pwd)"
debug "VS Code CLI: $(command -v code || echo not found)"
debug "curl: $(command -v curl || echo not found)"
debug "wget: $(command -v wget || echo not found)"
debug "file: $(command -v file || echo not found)"
debug "jq: $(command -v jq || echo not found)"

debug "Extension list file: $1"

if [ ! -f "$1" ]; then
  skipped_not_found+=("Extension list not found: $1")
  exit 1
fi

EXT_LIST_FILE="$1"
CODE_BIN="$(command -v code 2>/dev/null || true)"

debug "CODE_BIN resolved to: $CODE_BIN"

if [ -z "$CODE_BIN" ]; then
  for username in gig admin; do
    for candidate in \
      "/mnt/c/Users/$username/AppData/Local/Programs/Microsoft VS Code/bin/code" \
      "/mnt/c/Users/$username/AppData/Local/Programs/Microsoft VS Code Insiders/bin/code" \
      "/mnt/c/Users/$username/scoop/apps/vscode/current/bin/code"
    do
      debug "Checking candidate: $candidate"
      if [ -x "$candidate" ]; then
        CODE_BIN="$candidate"
        debug "Found code binary at: $candidate"
        break 2
      fi
    done
  done
  for candidate in \
    "/mnt/c/Program Files/Microsoft VS Code/bin/code" \
    "/mnt/c/Program Files (x86)/Microsoft VS Code/bin/code"
  do
    debug "Checking candidate: $candidate"
    if [ -x "$candidate" ]; then
      CODE_BIN="$candidate"
      debug "Found code binary at: $candidate"
      break
    fi
  done
fi

if [ -z "$CODE_BIN" ]; then
  failed+=("VS Code CLI (code) not found in PATH or common locations. Extensions will not be installed.")
  exit 0
fi

debug "Final CODE_BIN: $CODE_BIN"

if command -v curl >/dev/null 2>&1; then
  DL_CMD="curl -s -A 'Mozilla/5.0' -fSL -o"
  DL_CMD_RAW="curl -s -A 'Mozilla/5.0' -fSL"
elif command -v wget >/dev/null 2>&1; then
  DL_CMD="wget -q --user-agent='Mozilla/5.0' -O"
  DL_CMD_RAW="wget -q --user-agent='Mozilla/5.0' -O-"
else
  echo "Neither curl nor wget found. Please install one to download VSIX files."
  exit 1
fi

debug "DL_CMD: $DL_CMD"
debug "DL_CMD_RAW: $DL_CMD_RAW"

debug "Getting list of already installed extensions..."
mapfile -t already_installed < <("$CODE_CMD" --list-extensions 2>/dev/null)
debug "Already installed: ${already_installed[*]}"

failover=0

function download_marketplace_vsix() {
  local publisher="$1"
  local name="$2"
  local extid="$publisher.$name"
  local api_url="https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery"
  local vsix_url version
  local payload='{ "filters": [ { "criteria": [ { "filterType": 7, "value": "'"$extid"'" } ] } ], "flags": 914 }'
  local response
  debug "Querying Marketplace for $extid ..."
  debug "Marketplace API URL: $api_url"
  response=$(curl -sS -A 'Mozilla/5.0' -fSL "$api_url" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json;api-version=3.0-preview.1" \
    --data-binary @- <<< "$payload")
  version=$(echo "$response" | jq -r '.results[0].extensions[0].versions[0].version // empty')
  debug "Marketplace version for $extid: $version"
  if [ -z "$version" ]; then
    return 1
  fi
  vsix_url=$(echo "$response" | jq -r '.results[0].extensions[0].versions[0].assetUri + "/Microsoft.VisualStudio.Services.VSIXPackage"')
  debug "Marketplace VSIX URL for $extid: $vsix_url"
  if [ -z "$vsix_url" ]; then
    return 1
  fi
  local vsix_file="/tmp/$publisher.$name-$version.vsix"
  debug "Downloading from Marketplace: $vsix_url -> $vsix_file"
  curl -sS -A 'Mozilla/5.0' -fSL -o "$vsix_file" "$vsix_url" >/dev/null 2>&1
  if [ $? -eq 0 ] && file "$vsix_file" | grep -q 'Zip archive data'; then
    debug "Downloaded valid VSIX from Marketplace: $vsix_file"
    echo "$vsix_file"
    return 0
  else
    debug "Failed to download valid VSIX from Marketplace for $extid"
    [ -f "$vsix_file" ] && {
      debug "First 10 lines of failed VSIX file:"
      # head -10 "$vsix_file"
      rm -f "$vsix_file"
    }
    return 1
  fi
}

function download_openvsx_vsix() {
  debug "[OPENVSX] Entered download_openvsx_vsix for $1.$2"
  local publisher="$1"
  local name="$2"
  local api_url="https://open-vsx.org/api/$publisher/$name"
  debug "Querying Open VSX for $publisher.$name ..."
  debug "Open VSX API URL: $api_url"
  local latest_version
  latest_version=$(curl -sS -A 'Mozilla/5.0' "$api_url" | jq -r '.version // empty')
  debug "Open VSX version for $publisher.$name: $latest_version"
  if [ -z "$latest_version" ]; then
    debug "[OPENVSX] No version found for $publisher.$name on Open VSX. Skipping download."
    return 1
  fi
  local vsix_url="https://open-vsx.org/api/$publisher/$name/$latest_version/file/$publisher.$name-$latest_version.vsix"
  debug "Constructed Open VSX VSIX URL: $vsix_url"
  local vsix_file="/tmp/$publisher.$name-$latest_version.vsix"
  debug "Downloading from Open VSX: $vsix_url -> $vsix_file"
  $DL_CMD "$vsix_file" "$vsix_url" >/dev/null 2>&1
  if [ $? -eq 0 ] && file "$vsix_file" | grep -q 'Zip archive data'; then
    debug "Downloaded valid VSIX from Open VSX: $vsix_file"
    echo "$vsix_file"
    return 0
  else
    debug "Failed to download valid VSIX from Open VSX for $publisher.$name"
    [ -f "$vsix_file" ] && {
      debug "First 10 lines of failed VSIX file:"
      # head -10 "$vsix_file"
      rm -f "$vsix_file"
    }
    return 1
  fi
}

CACHE_DIR="$HOME/.cache/vscode-vsix"
mkdir -p "$CACHE_DIR"

# Remove custom user data dir, use default
CODE_CMD="$CODE_BIN"

# Get list of already installed extensions and their versions
mapfile -t already_installed < <("$CODE_CMD" --list-extensions 2>/dev/null)
declare -A installed_versions
while read -r line; do
  extid="${line%% *}"
  ver=$("$CODE_CMD" --show-versions | grep "^$extid@" | cut -d'@' -f2)
  [ -n "$ver" ] && installed_versions[$extid]="$ver"
done < <("$CODE_CMD" --list-extensions 2>/dev/null)

# Pre-process extension list
mapfile -t declared_exts < <(jq -r '.[]' "$EXT_LIST_FILE" | tr -d '\0')
to_install=()
to_update=()
skipped_already_installed=()
skipped_not_found=()

is_extension_available() {
  publisher="$1"
  name="$2"
  # Check Open VSX
  if curl -sS -A 'Mozilla/5.0' "https://open-vsx.org/api/$publisher/$name" | jq -e '.name' >/dev/null; then
    return 0
  fi
  # Check Marketplace
  local api_url="https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery"
  local extid="$publisher.$name"
  local payload='{ "filters": [ { "criteria": [ { "filterType": 7, "value": "'"$extid"'" } ] } ], "flags": 914 }'
  local response
  response=$(curl -sS -A 'Mozilla/5.0' -fSL "$api_url" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json;api-version=3.0-preview.1" \
    --data-binary @- <<< "$payload")
  if echo "$response" | jq -e '.results[0].extensions[0].extensionName' >/dev/null; then
    return 0
  fi
  return 1
}

for ext in "${declared_exts[@]}"; do
  publisher="${ext%%.*}"
  name="${ext#*.}"
  # Check if extension is available
  if ! is_extension_available "$publisher" "$name"; then
    skipped_not_found+=("$ext (not available on Open VSX or Marketplace)")
    continue
  fi
  # Get installed version
  current_version="${installed_versions[$ext]}"
  # Get latest version from Open VSX
  latest_version_ovsx=$(curl -sS -A 'Mozilla/5.0' "https://open-vsx.org/api/$publisher/$name" | jq -r '.version // empty')
  # Get latest version from Marketplace
  latest_version_marketplace=""
  response=$(curl -sS -A 'Mozilla/5.0' -fSL "https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json;api-version=3.0-preview.1" \
    --data-binary @- <<< '{ "filters": [ { "criteria": [ { "filterType": 7, "value": "'$publisher.$name'" } ] } ], "flags": 914 }')
  latest_version_marketplace=$(echo "$response" | jq -r '.results[0].extensions[0].versions[0].version // empty')
  # Determine latest version from either source
  latest_version="$latest_version_ovsx"
  if [ -n "$latest_version_marketplace" ]; then
    latest_version="$latest_version_marketplace"
  fi
  # If not installed, add to install
  if [ -z "$current_version" ]; then
    to_install+=("$ext")
    continue
  fi
  # If installed and up-to-date, skip
  if [ -n "$current_version" ] && [ -n "$latest_version" ] && [ "$current_version" = "$latest_version" ]; then
    skipped_already_installed+=("$ext")
    continue
  fi
  # If installed but outdated, add to update
  if [ -n "$current_version" ] && [ -n "$latest_version" ] && [ "$current_version" != "$latest_version" ]; then
    to_update+=("$ext|$current_version|$latest_version")
    continue
  fi
done

# Use temp files for parallel-safe result collection
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"; print_summary' EXIT

INSTALLED_EXTS_FILE="$TMPDIR/installed_exts"

install_extension() {
  ext="$1"
  publisher="${ext%%.*}"
  name="${ext#*.}"
  latest_version=$(curl -sS -A 'Mozilla/5.0' "https://open-vsx.org/api/$publisher/$name" | jq -r '.version // empty')
  vsix_file=""
  # Try Open VSX first
  if [ -n "$latest_version" ]; then
    vsix_file="$CACHE_DIR/$publisher.$name-$latest_version.vsix"
    if [ ! -f "$vsix_file" ]; then
      url="https://open-vsx.org/api/$publisher/$name/$latest_version/file/$publisher.$name-$latest_version.vsix"
      $DL_CMD "$vsix_file" "$url" >/dev/null 2>&1
    fi
    if [ -f "$vsix_file" ] && file "$vsix_file" | grep -q 'Zip archive data'; then
      install_output=$("$CODE_CMD" --install-extension "$vsix_file" --force 2>&1)
      if echo "$install_output" | grep -qi 'success'; then
        echo "$ext" >> "$TMPDIR/installed"
      else
        echo "$ext (install failed)" >> "$TMPDIR/failed"
      fi
      return
    fi
  fi
  # Fallback: try Marketplace
  vsix_file="$CACHE_DIR/$publisher.$name-marketplace.vsix"
  if [ ! -f "$vsix_file" ]; then
    mp_vsix=$(download_marketplace_vsix "$publisher" "$name")
    [ -n "$mp_vsix" ] && mv "$mp_vsix" "$vsix_file"
  fi
  if [ -f "$vsix_file" ] && file "$vsix_file" | grep -q 'Zip archive data'; then
    install_output=$("$CODE_CMD" --install-extension "$vsix_file" --force 2>&1)
    if echo "$install_output" | grep -qi 'success'; then
      echo "$ext" >> "$TMPDIR/installed"
    else
      echo "$ext (install failed)" >> "$TMPDIR/failed"
    fi
    return
  fi
  echo "$ext (not found)" >> "$TMPDIR/skipped_not_found"
}

# Add update_extension function
update_extension() {
  ext="$1"
  oldver="$2"
  newver="$3"
  publisher="${ext%%.*}"
  name="${ext#*.}"
  vsix_file="$CACHE_DIR/$publisher.$name-$newver.vsix"
  if [ ! -f "$vsix_file" ]; then
    url="https://open-vsx.org/api/$publisher/$name/$newver/file/$publisher.$name-$newver.vsix"
    $DL_CMD "$vsix_file" "$url" >/dev/null 2>&1
  fi
  if [ -f "$vsix_file" ] && file "$vsix_file" | grep -q 'Zip archive data'; then
    install_output=$("$CODE_CMD" --install-extension "$vsix_file" --force 2>&1)
    if echo "$install_output" | grep -qi 'success'; then
      echo "$ext ($oldver -> $newver)" >> "$TMPDIR/updated_exts"
    else
      echo "$ext (update failed)" >> "$TMPDIR/failed"
    fi
    return
  fi
  # Fallback: try Marketplace
  vsix_file="$CACHE_DIR/$publisher.$name-marketplace.vsix"
  if [ ! -f "$vsix_file" ]; then
    mp_vsix=$(download_marketplace_vsix "$publisher" "$name")
    [ -n "$mp_vsix" ] && mv "$mp_vsix" "$vsix_file"
  fi
  if [ -f "$vsix_file" ] && file "$vsix_file" | grep -q 'Zip archive data'; then
    install_output=$("$CODE_CMD" --install-extension "$vsix_file" --force 2>&1)
    if echo "$install_output" | grep -qi 'success'; then
      echo "$ext ($oldver -> $newver)" >> "$TMPDIR/updated_exts"
    else
      echo "$ext (update failed)" >> "$TMPDIR/failed"
    fi
    return
  fi
  echo "$ext (update not found)" >> "$TMPDIR/skipped_not_found"
}

# Only install/update missing or outdated extensions
CONCURRENCY=16
pids=()
# Install new extensions
for ext in "${to_install[@]}"; do
  install_extension "$ext" &
  pids+=("$!")
  if (( ${#pids[@]} >= CONCURRENCY )); then
    wait "${pids[0]}"
    pids=("${pids[@]:1}")
  fi
done
# Update outdated extensions
for extinfo in "${to_update[@]}"; do
  IFS='|' read -r ext oldver newver <<< "$extinfo"
  update_extension "$ext" "$oldver" "$newver" &
  pids+=("$!")
  if (( ${#pids[@]} >= CONCURRENCY )); then
    wait "${pids[0]}"
    pids=("${pids[@]:1}")
  fi
done
# Wait for remaining jobs
for pid in "${pids[@]}"; do
  wait "$pid"
done


# Remove extensions not in the declarative list
mapfile -t current_exts < <("$CODE_CMD" --list-extensions 2>/dev/null)
for ext in "${current_exts[@]}"; do
  found=0
  for declared in "${declared_exts[@]}"; do
    if [ "$ext" = "$declared" ]; then
      found=1
      break
    fi
  done
  if [ $found -eq 0 ]; then
    $CODE_CMD --uninstall-extension "$ext" --force >/dev/null 2>&1
    echo "$ext" >> "$TMPDIR/removed_exts"
  fi

done

# Aggregate results from temp files into arrays for summary
installed=(); [ -f "$TMPDIR/installed" ] && mapfile -t installed < "$TMPDIR/installed"
skipped_already_installed=(); [ -f "$TMPDIR/skipped_already_installed" ] && mapfile -t skipped_already_installed < "$TMPDIR/skipped_already_installed"
skipped_not_found=(); [ -f "$TMPDIR/skipped_not_found" ] && mapfile -t skipped_not_found < "$TMPDIR/skipped_not_found"
failed=(); [ -f "$TMPDIR/failed" ] && mapfile -t failed < "$TMPDIR/failed"
removed_exts=(); [ -f "$TMPDIR/removed_exts" ] && mapfile -t removed_exts < "$TMPDIR/removed_exts"
updated_exts=(); [ -f "$TMPDIR/updated_exts" ] && mapfile -t updated_exts < "$TMPDIR/updated_exts"

