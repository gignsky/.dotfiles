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
  if [ ${#removed_exts[@]} -gt 0 ]; then
    printf '\033[1;31m🗑️  Removed (not in declarative list):\033[0m\n'
    for ext in "${removed_exts[@]}"; do
      printf '  \033[1;31m🗑️  %s\033[0m\n' "$ext"
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

# debug "VSCode extension install script started at $(date)"
# debug "Script started."
# debug "PATH: $PATH"
# debug "User: $(whoami)"
# debug "Current directory: $(pwd)"
# debug "VS Code CLI: $(command -v code || echo not found)"
# debug "curl: $(command -v curl || echo not found)"
# debug "wget: $(command -v wget || echo not found)"
# debug "file: $(command -v file || echo not found)"
# debug "jq: $(command -v jq || echo not found)"

# debug "Extension list file: $1"

if [ ! -f "$1" ]; then
  skipped_not_found+=("Extension list not found: $1")
  exit 1
fi

EXT_LIST_FILE="$1"
CODE_BIN="$(command -v code 2>/dev/null || true)"

# debug "CODE_BIN resolved to: $CODE_BIN"

if [ -z "$CODE_BIN" ]; then
  for username in gig admin; do
    for candidate in \
      "/mnt/c/Users/$username/AppData/Local/Programs/Microsoft VS Code/bin/code" \
      "/mnt/c/Users/$username/AppData/Local/Programs/Microsoft VS Code Insiders/bin/code" \
      "/mnt/c/Users/$username/scoop/apps/vscode/current/bin/code"
    do
      # debug "Checking candidate: $candidate"
      if [ -x "$candidate" ]; then
        CODE_BIN="$candidate"
        # debug "Found code binary at: $candidate"
        break 2
      fi
    done
  done
  for candidate in \
    "/mnt/c/Program Files/Microsoft VS Code/bin/code" \
    "/mnt/c/Program Files (x86)/Microsoft VS Code/bin/code"
  do
    # debug "Checking candidate: $candidate"
    if [ -x "$candidate" ]; then
      CODE_BIN="$candidate"
      # debug "Found code binary at: $candidate"
      break
    fi
  done
fi

if [ -z "$CODE_BIN" ]; then
  failed+=("VS Code CLI (code) not found in PATH or common locations. Extensions will not be installed.")
  exit 0
fi

# debug "Final CODE_BIN: $CODE_BIN"

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

# debug "DL_CMD: $DL_CMD"
# debug "DL_CMD_RAW: $DL_CMD_RAW"

# debug "Getting list of already installed extensions..."
mapfile -t already_installed < <("$CODE_BIN" --list-extensions 2>/dev/null)
# debug "Already installed: ${already_installed[*]}"

failover=0

function download_marketplace_vsix() {
  local publisher="$1"
  local name="$2"
  local extid="$publisher.$name"
  local api_url="https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery"
  local vsix_url version
  local payload='{ "filters": [ { "criteria": [ { "filterType": 7, "value": "'"$extid"'" } ] } ], "flags": 914 }'
  local response
  # debug "Querying Marketplace for $extid ..."
  # debug "Marketplace API URL: $api_url"
  response=$(curl -sS -A 'Mozilla/5.0' -fSL "$api_url" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json;api-version=3.0-preview.1" \
    --data-binary @- <<< "$payload")
  version=$(echo "$response" | jq -r '.results[0].extensions[0].versions[0].version // empty')
  # debug "Marketplace version for $extid: $version"
  if [ -z "$version" ]; then
    return 1
  fi
  vsix_url=$(echo "$response" | jq -r '.results[0].extensions[0].versions[0].assetUri + "/Microsoft.VisualStudio.Services.VSIXPackage"')
  # debug "Marketplace VSIX URL for $extid: $vsix_url"
  if [ -z "$vsix_url" ]; then
    return 1
  fi
  local vsix_file="/tmp/$publisher.$name-$version.vsix"
  # debug "Downloading from Marketplace: $vsix_url -> $vsix_file"
  curl -sS -A 'Mozilla/5.0' -fSL -o "$vsix_file" "$vsix_url" >/dev/null 2>&1
  if [ $? -eq 0 ] && file "$vsix_file" | grep -q 'Zip archive data'; then
    # debug "Downloaded valid VSIX from Marketplace: $vsix_file"
    echo "$vsix_file"
    return 0
  else
    # debug "Failed to download valid VSIX from Marketplace for $extid"
    [ -f "$vsix_file" ] && {
      # debug "First 10 lines of failed VSIX file:"
      # head -10 "$vsix_file"
      rm -f "$vsix_file"
    }
    return 1
  fi
}

function download_openvsx_vsix() {
  # debug "[OPENVSX] Entered download_openvsx_vsix for $1.$2"
  local publisher="$1"
  local name="$2"
  local api_url="https://open-vsx.org/api/$publisher/$name"
  # debug "Querying Open VSX for $publisher.$name ..."
  # debug "Open VSX API URL: $api_url"
  local latest_version
  latest_version=$(curl -sS -A 'Mozilla/5.0' "$api_url" | jq -r '.version // empty')
  # debug "Open VSX version for $publisher.$name: $latest_version"
  if [ -z "$latest_version" ]; then
    # debug "[OPENVSX] No version found for $publisher.$name on Open VSX. Skipping download."
    return 1
  fi
  local vsix_url="https://open-vsx.org/api/$publisher/$name/$latest_version/file/$publisher.$name-$latest_version.vsix"
  # debug "Constructed Open VSX VSIX URL: $vsix_url"
  local vsix_file="/tmp/$publisher.$name-$latest_version.vsix"
  # debug "Downloading from Open VSX: $vsix_url -> $vsix_file"
  $DL_CMD "$vsix_file" "$vsix_url" >/dev/null 2>&1
  if [ $? -eq 0 ] && file "$vsix_file" | grep -q 'Zip archive data'; then
    # debug "Downloaded valid VSIX from Open VSX: $vsix_file"
    echo "$vsix_file"
    return 0
  else
    # debug "Failed to download valid VSIX from Open VSX for $publisher.$name"
    [ -f "$vsix_file" ] && {
      # debug "First 10 lines of failed VSIX file:"
      # head -10 "$vsix_file"
      rm -f "$vsix_file"
    }
    return 1
  fi
}

CACHE_DIR="$HOME/.cache/vscode-vsix"
mkdir -p "$CACHE_DIR"

# Get list of already installed extensions and their versions
mapfile -t already_installed < <("$CODE_BIN" --list-extensions 2>/dev/null)
declare -A installed_versions
while read -r line; do
  extid="${line%% *}"
  ver=$("$CODE_BIN" --show-versions | grep "^$extid@" | cut -d'@' -f2)
  [ -n "$ver" ] && installed_versions[$extid]="$ver"
done < <("$CODE_BIN" --list-extensions 2>/dev/null)

# Function to install a single extension (to be run in parallel)
install_extension() {
  ext="$1"
  publisher="${ext%%.*}"
  name="${ext#*.}"
  vsix_file=""
  # Check if already installed
  if printf '%s\n' "${already_installed[@]}" | grep -qx "$ext"; then
    skipped_already_installed+=("$ext")
    return
  fi
  # Try to use cached VSIX first
  latest_version=""
  vsix_file="$CACHE_DIR/$publisher.$name-latest.vsix"
  # Get latest version from Open VSX (faster, no auth)
  latest_version=$(curl -sS -A 'Mozilla/5.0' "https://open-vsx.org/api/$publisher/$name" | jq -r '.version // empty')
  if [ -n "$latest_version" ]; then
    vsix_file="$CACHE_DIR/$publisher.$name-$latest_version.vsix"
    if [ ! -f "$vsix_file" ]; then
      url="https://open-vsx.org/api/$publisher/$name/$latest_version/file/$publisher.$name-$latest_version.vsix"
      $DL_CMD "$vsix_file" "$url" >/dev/null 2>&1
    fi
    if [ -f "$vsix_file" ] && file "$vsix_file" | grep -q 'Zip archive data'; then
      "$CODE_BIN" --install-extension "$vsix_file" --force >/dev/null 2>&1 && installed+=("$ext") || failed+=("$ext (install failed)")
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
    "$CODE_BIN" --install-extension "$vsix_file" --force >/dev/null 2>&1 && installed+=("$ext") || failed+=("$ext (install failed)")
    return
  fi
  skipped_not_found+=("$ext")
}

# Parallel install loop with concurrency limit
CONCURRENCY=6
pids=()
while IFS= read -r ext; do
  install_extension "$ext" &
  pids+=("$!")
  # Limit concurrency
  if (( ${#pids[@]} >= CONCURRENCY )); then
    wait "${pids[0]}"
    pids=("${pids[@]:1}")
  fi
done < <(jq -r '.[]' "$EXT_LIST_FILE" | tr -d '\0')
# Wait for remaining jobs
for pid in "${pids[@]}"; do
  wait "$pid"
done

# Remove extensions not in the declarative list
mapfile -t declared_exts < <(jq -r '.[]' "$EXT_LIST_FILE" | tr -d '\0')
mapfile -t current_exts < <("$CODE_BIN" --list-extensions 2>/dev/null)
for ext in "${current_exts[@]}"; do
  found=0
  for declared in "${declared_exts[@]}"; do
    if [ "$ext" = "$declared" ]; then
      found=1
      break
    fi
  done
  if [ $found -eq 0 ]; then
    "$CODE_BIN" --uninstall-extension "$ext" --force >/dev/null 2>&1
    removed_exts+=("$ext")
  fi

done

# Only update extensions if version is out of date
for ext in "${declared_exts[@]}"; do
  publisher="${ext%%.*}"
  name="${ext#*.}"
  latest_version=$(curl -sS -A 'Mozilla/5.0' "https://open-vsx.org/api/$publisher/$name" | jq -r '.version // empty')
  current_version="${installed_versions[$ext]}"
  if [ -n "$latest_version" ] && [ "$latest_version" != "$current_version" ]; then
    vsix_file="$CACHE_DIR/$publisher.$name-$latest_version.vsix"
    if [ ! -f "$vsix_file" ]; then
      url="https://open-vsx.org/api/$publisher/$name/$latest_version/file/$publisher.$name-$latest_version.vsix"
      $DL_CMD "$vsix_file" "$url" >/dev/null 2>&1
    fi
    if [ -f "$vsix_file" ] && file "$vsix_file" | grep -q 'Zip archive data'; then
      "$CODE_BIN" --install-extension "$vsix_file" --force >/dev/null 2>&1 && updated_exts+=("$ext")
    fi
  fi
done
