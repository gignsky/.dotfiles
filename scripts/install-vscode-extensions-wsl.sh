#!/usr/bin/env bash
# Install VS Code extensions from a JSON file (for WSL)
# Usage: ./install-vscode-extensions-wsl.sh /path/to/extensions.json

set -euo pipefail

DEBUG=${DEBUG:-1}
function debug() { [ "$DEBUG" = 1 ] && echo -e "[DEBUG] $@"; }

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

EXT_LIST_FILE="$1"

if [ ! -f "$EXT_LIST_FILE" ]; then
  echo "Extension list not found: $EXT_LIST_FILE"
  exit 1
fi

# Try to find the VS Code CLI
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
  echo "VS Code CLI (code) not found in PATH or common locations. Extensions will not be installed."
  exit 0
fi

debug "Final CODE_BIN: $CODE_BIN"

# Set download commands based on DEBUG
if command -v curl >/dev/null 2>&1; then
  if [ "$DEBUG" = 1 ]; then
    DL_CMD="curl -A 'Mozilla/5.0' -fSL -o"
    DL_CMD_RAW="curl -A 'Mozilla/5.0' -fSL"
  else
    DL_CMD="curl -A 'Mozilla/5.0' -fsSL -o"
    DL_CMD_RAW="curl -A 'Mozilla/5.0' -fsSL"
  fi
elif command -v wget >/dev/null 2>&1; then
  if [ "$DEBUG" = 1 ]; then
    DL_CMD="wget --user-agent='Mozilla/5.0' -O"
    DL_CMD_RAW="wget --user-agent='Mozilla/5.0' -O-"
  else
    DL_CMD="wget --user-agent='Mozilla/5.0' -qO"
    DL_CMD_RAW="wget --user-agent='Mozilla/5.0' -qO-"
  fi
else
  echo "Neither curl nor wget found. Please install one to download VSIX files."
  exit 1
fi

debug "DL_CMD: $DL_CMD"
debug "DL_CMD_RAW: $DL_CMD_RAW"

installed=()
skipped=()
failed=()

debug "Getting list of already installed extensions..."
mapfile -t already_installed < <("$CODE_BIN" --list-extensions 2>/dev/null)
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
  if command -v curl >/dev/null 2>&1; then
    if [ "$DEBUG" = 1 ]; then
      response=$(curl -A 'Mozilla/5.0' -fSL "$api_url" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json;api-version=3.0-preview.1" \
        --data-binary @- <<< "$payload")
    else
      response=$(curl -A 'Mozilla/5.0' -fsSL "$api_url" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json;api-version=3.0-preview.1" \
        --data-binary @- <<< "$payload" 2>/dev/null)
    fi
  elif command -v wget >/dev/null 2>&1; then
    if [ "$DEBUG" = 1 ]; then
      debug "[WARN] Marketplace API with wget may not support POST."
      response=$(wget --user-agent='Mozilla/5.0' --header="Content-Type: application/json" --header="Accept: application/json;api-version=3.0-preview.1" --post-data="$payload" "$api_url" -O -)
    else
      response=$(wget --user-agent='Mozilla/5.0' --header="Content-Type: application/json" --header="Accept: application/json;api-version=3.0-preview.1" --post-data="$payload" "$api_url" -qO-)
    fi
  else
    debug "No curl or wget found for Marketplace API call."
    return 1
  fi
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
  if [ "$DEBUG" = 1 ]; then
    curl -A 'Mozilla/5.0' -fSL -o "$vsix_file" "$vsix_url"
  else
    curl -A 'Mozilla/5.0' -fsSL -o "$vsix_file" "$vsix_url" 2>/dev/null
  fi
  if [ $? -eq 0 ] && file "$vsix_file" | grep -q 'Zip archive data'; then
    debug "Downloaded valid VSIX from Marketplace: $vsix_file"
    echo "$vsix_file"
    return 0
  else
    debug "Failed to download valid VSIX from Marketplace for $extid"
    [ -f "$vsix_file" ] && {
      debug "First 10 lines of failed VSIX file:"
      head -10 "$vsix_file"
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
  if command -v curl >/dev/null 2>&1; then
    if [ "$DEBUG" = 1 ]; then
      latest_version=$(curl -A 'Mozilla/5.0' -S "$api_url" | jq -r '.version // empty')
    else
      latest_version=$(curl -A 'Mozilla/5.0' -s "$api_url" | jq -r '.version // empty')
    fi
  else
    if [ "$DEBUG" = 1 ]; then
      latest_version=$(wget --user-agent='Mozilla/5.0' "$api_url" -O - | jq -r '.version // empty')
    else
      latest_version=$(wget --user-agent='Mozilla/5.0' -qO- "$api_url" | jq -r '.version // empty')
    fi
  fi
  debug "Open VSX version for $publisher.$name: $latest_version"
  if [ -z "$latest_version" ]; then
    debug "[OPENVSX] No version found for $publisher.$name on Open VSX. Skipping download."
    return 1
  fi
  local vsix_url="https://open-vsx.org/api/$publisher/$name/$latest_version/file/$publisher.$name-$latest_version.vsix"
  debug "Constructed Open VSX VSIX URL: $vsix_url"
  local vsix_file="/tmp/$publisher.$name-$latest_version.vsix"
  debug "Downloading from Open VSX: $vsix_url -> $vsix_file"
  if [ "$DEBUG" = 1 ]; then
    $DL_CMD "$vsix_file" "$vsix_url"
  else
    $DL_CMD "$vsix_file" "$vsix_url" 2>/dev/null
  fi
  if [ $? -eq 0 ] && file "$vsix_file" | grep -q 'Zip archive data'; then
    debug "Downloaded valid VSIX from Open VSX: $vsix_file"
    echo "$vsix_file"
    return 0
  else
    debug "Failed to download valid VSIX from Open VSX for $publisher.$name"
    [ -f "$vsix_file" ] && {
      debug "First 10 lines of failed VSIX file:"
      head -10 "$vsix_file"
      rm -f "$vsix_file"
    }
    return 1
  fi
}

debug "Starting extension install loop..."
set +e  # Disable exit on error for the loop
while IFS= read -r ext; do
  debug "Processing $ext ..."
  if printf '%s\n' "${already_installed[@]}" | grep -qx "$ext"; then
    debug "$ext is already installed, skipping."
    skipped+=("$ext (already installed)")
    continue
  fi
  publisher="${ext%%.*}"
  name="${ext#*.}"
  vsix_file=""
  if [ "$failover" -eq 0 ]; then
    vsix_file=$(download_marketplace_vsix "$publisher" "$name" | tr -d '\0') || true
    if [ -n "$vsix_file" ] && [ -f "$vsix_file" ]; then
      debug "Installing $ext from Marketplace VSIX: $vsix_file"
      "$CODE_BIN" --install-extension "$vsix_file" --force >/dev/null 2>&1 && installed+=("$ext") || failed+=("$ext")
      rm -f "$vsix_file"
      continue
    fi
    debug "Marketplace failed for $ext, switching to failover."
    failover=1
  fi
  download_openvsx_vsix "$publisher" "$name"
  vsix_file=$(ls /tmp/"$publisher.$name"-*.vsix 2>/dev/null | head -n1)
  if [ -n "$vsix_file" ] && [ -f "$vsix_file" ]; then
    debug "Installing $ext from Open VSX VSIX: $vsix_file"
    "$CODE_BIN" --install-extension "$vsix_file" --force >/dev/null 2>&1 && installed+=("$ext") || failed+=("$ext")
    rm -f "$vsix_file"
    continue
  fi
  debug "Failed to install $ext from both sources."
  skipped+=("$ext")
done < <(jq -r '.[]' "$EXT_LIST_FILE" | tr -d '\0')
set -e  # Re-enable exit on error

debug "Extension install loop complete."

# Troubleshooting: print if output is a terminal
if [ -t 1 ]; then
  debug "[SUMMARY] Output is a terminal. Colors should work."
else
  debug "[SUMMARY] Output is NOT a terminal. Colors may not display."
fi

# Beautified summary with spacing, headers, and emojis
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
if [ ${#skipped[@]} -gt 0 ]; then
  printf '\033[1;33m⚠️  Skipped (already installed or not found):\033[0m\n'
  for ext in "${skipped[@]}"; do
    printf '  \033[1;33m⏭️  %s\033[0m\n' "$ext"
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
