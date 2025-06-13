#!/usr/bin/env bash

# Initialize summary arrays at the very top so they are always available
installed=()
skipped_already_installed=()
skipped_not_found=()
failed=()
removed_exts=()
updated_exts=()

# Option to skip showing already installed extensions in summary
SKIP_ALREADY_INSTALLED_SUMMARY="${SKIP_ALREADY_INSTALLED_SUMMARY:-0}"
# echo "SKIP_ALREADY_INSTALLED_SUMMARY is set to $SKIP_ALREADY_INSTALLED_SUMMARY"
# exit 0 # used for debugging

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
  if [ "$SKIP_ALREADY_INSTALLED_SUMMARY" != "1" ] && [ ${#skipped_already_installed[@]} -gt 0 ]; then
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

DEBUG="${DEBUG:-0}"
# Enhanced debug function with levels
function debug() {
  local level=1
  if [[ "$1" =~ ^[0-9]+$ ]]; then
    level="$1"
    shift
  fi
  if [ "$DEBUG" -ge "$level" ]; then
    echo -e "[DEBUG] $@" >&2
  fi
}

export PATH="/bin:/usr/bin:$PATH"

debug 1 "VSCode extension install script started at $(date)"
debug 2 "Script started."
debug 4 "PATH: $PATH"
debug 4 "User: $(whoami)"
debug 4 "Current directory: $(pwd)"
debug 4 "VS Code CLI: $(command -v code || echo not found)"
debug 4 "curl: $(command -v curl || echo not found)"
debug 4 "wget: $(command -v wget || echo not found)"
debug 4 "file: $(command -v file || echo not found)"
debug 4 "jq: $(command -v jq || echo not found)"

debug 3 "Extension list file: $1"

if [ ! -f "$1" ]; then
  skipped_not_found+=("Extension list not found: $1")
  exit 1
fi

EXT_LIST_FILE="$1"
CODE_BIN="$(command -v code 2>/dev/null || true)"

debug 3 "CODE_BIN resolved to: $CODE_BIN"

if [ -z "$CODE_BIN" ]; then
  for username in gig admin; do
    for candidate in \
      "/mnt/c/Users/$username/AppData/Local/Programs/Microsoft VS Code/bin/code" \
      "/mnt/c/Users/$username/AppData/Local/Programs/Microsoft VS Code Insiders/bin/code" \
      "/mnt/c/Users/$username/scoop/apps/vscode/current/bin/code"
    do
      debug 3 "Checking candidate: $candidate"
      if [ -x "$candidate" ]; then
        CODE_BIN="$candidate"
        debug 2 "Found code binary at: $candidate"
        break 2
      fi
    done
  done
  for candidate in \
    "/mnt/c/Program Files/Microsoft VS Code/bin/code" \
    "/mnt/c/Program Files (x86)/Microsoft VS Code/bin/code"
  do
    debug 3 "Checking candidate: $candidate"
    if [ -x "$candidate" ]; then
      CODE_BIN="$candidate"
      debug 2 "Found code binary at: $candidate"
      break
    fi
  done
fi

if [ -z "$CODE_BIN" ]; then
  failed+=("VS Code CLI (code) not found in PATH or common locations. Extensions will not be installed.")
  exit 0
fi

debug 1 "Final CODE_BIN: $CODE_BIN"

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

debug 4 "DL_CMD: $DL_CMD"
debug 4 "DL_CMD_RAW: $DL_CMD_RAW"


function download_openvsx_vsix() {
  debug 1 "[OPENVSX] Entered download_openvsx_vsix for $1.$2"
  local publisher="$1"
  local name="$2"
  local api_url="https://open-vsx.org/api/$publisher/$name"
  debug 2 "Querying Open VSX for $publisher.$name ..."
  debug 3 "Open VSX API URL: $api_url"
  local latest_version
  latest_version=$(curl -sS -A 'Mozilla/5.0' "$api_url" | jq -r '.version // empty')
  debug 2 "Open VSX version for $publisher.$name: $latest_version"
  if [ -z "$latest_version" ]; then
    debug 2 "[OPENVSX] No version found for $publisher.$name on Open VSX. Skipping download."
    return 1
  fi
  local vsix_url="https://open-vsx.org/api/$publisher/$name/$latest_version/file/$publisher.$name-$latest_version.vsix"
  debug 3 "Constructed Open VSX VSIX URL: $vsix_url"
  local vsix_file="/tmp/$publisher.$name-$latest_version.vsix"
  debug 2 "Downloading from Open VSX: $vsix_url -> $vsix_file"
  $DL_CMD "$vsix_file" "$vsix_url" >/dev/null 2>&1
  if [ $? -eq 0 ] && file "$vsix_file" | grep -q 'Zip archive data'; then
    debug 1 "Downloaded valid VSIX from Open VSX: $vsix_file"
    echo "$vsix_file"
    return 0
  else
    debug 1 "Failed to download valid VSIX from Open VSX for $publisher.$name"
    [ -f "$vsix_file" ] && {
      debug 4 "First 10 lines of failed VSIX file:"
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
# Use code --list-extensions --show-versions and parse it efficiently
mapfile -t show_versions_lines < <("$CODE_CMD" --list-extensions --show-versions 2>/dev/null)
declare -A installed_versions
declare -A normalized_installed_versions
for line in "${show_versions_lines[@]}"; do
  # Each line is like: extid@version
  extid="${line%%@*}"
  ver="${line#*@}"
  norm_extid="${extid,,}"
  [ -n "$extid" ] && [ -n "$ver" ] && installed_versions[$extid]="$ver"
  [ -n "$extid" ] && [ -n "$ver" ] && normalized_installed_versions[$norm_extid]="$ver"
done
debug 2 "Raw code --list-extensions --show-versions output: ${show_versions_lines[*]}"
debug 1 "Normalized installed extension IDs (with versions):"
for k in "${!normalized_installed_versions[@]}"; do
  debug 1 "  $k -> ${normalized_installed_versions[$k]}"
done

# Get normalized list of installed extensions (no versions)
# Use code --list-extensions and parse it efficiently
mapfile -t installed_exts_raw < <("$CODE_CMD" --list-extensions 2>/dev/null)
normalized_installed=()
for ext in "${installed_exts_raw[@]}"; do
  normalized_installed+=("${ext,,}")
  done

debug 2 "Raw installed extensions (no versions): ${installed_exts_raw[*]}"
debug 1 "Normalized installed extensions (no versions):"
for ext in "${normalized_installed[@]}"; do
  debug 1 "  $ext"
done

# Pre-process extension list
mapfile -t declared_exts < <(jq -r '.[]' "$EXT_LIST_FILE" | tr -d '\0')
declared_exts_normalized=()
for ext in "${declared_exts[@]}"; do
  declared_exts_normalized+=("${ext,,}")
done
debug 2 "Normalized declared extension IDs: ${declared_exts_normalized[*]}"

to_install=()
to_update=()
skipped_already_installed=()
skipped_not_found=()

is_extension_available() {
  debug 2 "Checking availability for extension: $1.$2"
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

process_declared_ext() {
  local ext="$1"
  local result_file="$2"
  local publisher="${ext%%.*}"
  local name="${ext#*.}"
  local norm_ext="${ext,,}"
  debug 1 "[process_declared_ext] $ext (publisher: $publisher, name: $name, normalized: $norm_ext)"
  # Check if extension is available on Open VSX or Marketplace
  if ! is_extension_available "$publisher" "$name"; then
    debug "Extension $ext is NOT available on Open VSX or Marketplace"
    echo "SKIP_NOT_FOUND|$ext (not available on Open VSX or Marketplace)" >> "$result_file"
    return
  fi
  # Get installed version using normalized ID
  current_version="${normalized_installed_versions[$norm_ext]}"
  debug 2 "Installed version for $ext: ${current_version:-<not installed>}"
  # Get latest version from Open VSX
  latest_version_ovsx=$(curl -sS -A 'Mozilla/5.0' "https://open-vsx.org/api/$publisher/$name" | jq -r '.version // empty')
  debug 3 "Latest version on Open VSX for $ext: ${latest_version_ovsx:-<none>}"
  # Get latest version from Marketplace
  latest_version_marketplace=""
  response=$(curl -sS -A 'Mozilla/5.0' -fSL "https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json;api-version=3.0-preview.1" \
    --data-binary @- <<< '{ "filters": [ { "criteria": [ { "filterType": 7, "value": "'$publisher.$name'" } ] } ], "flags": 914 }')
  latest_version_marketplace=$(echo "$response" | jq -r '.results[0].extensions[0].versions[].version' | sort -V | tail -n1)
  debug 3 "Latest version on Marketplace for $ext: ${latest_version_marketplace:-<none>}"
  # Determine latest version from either source
  latest_version="$latest_version_ovsx"
  if [ -n "$latest_version_marketplace" ]; then
    latest_version="$latest_version_marketplace"
  fi
  debug 1 "Selected latest version for $ext: ${latest_version:-<none>}"
  # If not installed, add to install
  if [ -z "$current_version" ]; then
    debug "Adding $ext to to_install"
    echo "INSTALL|$ext" >> "$result_file"
    return
  fi
  # If installed and up-to-date, skip
  if [ -n "$current_version" ] && [ -n "$latest_version" ] && [ "$current_version" = "$latest_version" ]; then
    debug 1 "Skipping $ext (already installed and up-to-date)"
    echo "SKIP_ALREADY_INSTALLED|$ext" >> "$result_file"
    return
  fi
  # If installed but outdated, add to update
  if [ -n "$current_version" ] && [ -n "$latest_version" ] && [ "$current_version" != "$latest_version" ]; then
    debug 1 "Adding $ext to to_update ($current_version -> $latest_version)"
    echo "UPDATE|$ext|$current_version|$latest_version" >> "$result_file"
    return
  fi
}

process_installed_ext() {
  local ext="$1"
  local result_file="$2"
  local norm_ext="$ext"
  debug 1 "[process_installed_ext] $ext (normalized: $norm_ext)"
  local found=0
  for declared in "${declared_exts_normalized[@]}"; do
    if [ "$norm_ext" = "$declared" ]; then
      debug 1 "[process_installed_ext] Extension $ext is declared; skipping removal."
      found=1
      break
    fi
  done
  if [ $found -eq 0 ]; then
    debug 1 "[process_installed_ext] Extension $ext is installed but not declared; marking for removal."
    echo "REMOVE|$ext" >> "$result_file"
  fi
}

process_extension() {
  debug 2 "[process_extension] Processing extension: $1 (mode: $3)"
  local ext="$1"
  local result_file="$2"
  local mode="$3"
  case "$mode" in
    declared_exts)
      process_declared_ext "$ext" "$result_file"
      ;;
    installed_exts)
      process_installed_ext "$ext" "$result_file"
      ;;
    *)
      debug "[process_extension] Unknown mode: $mode"
      ;;
  esac
}

# Now process installed extensions in parallel
debug 1 "Processing installed extensions (in parallel)..."
TMP_PROCESS_INSTALLED=$(mktemp)
> "$TMP_PROCESS_INSTALLED"
pids=()
CONCURRENCY=16
for ext in "${normalized_installed[@]}"; do
  process_extension "$ext" "$TMP_PROCESS_INSTALLED" installed_exts &
  pids+=("$!")
  if (( ${#pids[@]} >= CONCURRENCY )); then
    wait "${pids[0]}"
    pids=("${pids[@]:1}")
  fi
done
for pid in "${pids[@]}"; do
  wait "$pid"
done
# Collect REMOVE results
while IFS= read -r line; do
  IFS='|' read -r action ext <<< "$line"
  case "$action" in
    REMOVE) to_remove+=("$ext") ;;
  esac
done < "$TMP_PROCESS_INSTALLED"
rm -f "$TMP_PROCESS_INSTALLED"

# Parallelize extension processing
debug 1 "Checking availability for all declared extensions (in parallel)..."
TMP_PROCESS_DECLARED=$(mktemp)
> "$TMP_PROCESS_DECLARED"
CONCURRENCY=16
pids=()
for ext in "${declared_exts[@]}"; do
  process_extension "$ext" "$TMP_PROCESS_DECLARED" declared_exts &
  pids+=("$!")
  if (( ${#pids[@]} >= CONCURRENCY )); then
    wait "${pids[0]}"
    pids=("${pids[@]:1}")
  fi
done
for pid in "${pids[@]}"; do
  wait "$pid"
done

# Collect results
while IFS= read -r line; do
  IFS='|' read -r action ext oldver newver <<< "$line"
  case "$action" in
    INSTALL) to_install+=("$ext") ;;
    UPDATE) to_update+=("$ext|$oldver|$newver") ;;
    SKIP_ALREADY_INSTALLED) skipped_already_installed+=("$ext");;
    SKIP_NOT_FOUND) skipped_not_found+=("$ext");;
  esac
done < "$TMP_PROCESS_DECLARED"
# Use temp files for parallel-safe result collection
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"; print_summary' EXIT

INSTALLED_EXTS_FILE="$TMPDIR/installed_exts"

# Write skipped_already_installed to TMPDIR for summary
if [ ${#skipped_already_installed[@]} -gt 0 ]; then
  printf "%s\n" "${skipped_already_installed[@]}" > "$TMPDIR/skipped_already_installed"
fi
rm -f "$TMP_PROCESS_DECLARED"

debug 1 "to_install:"
for ext in "${to_install[@]}"; do
  debug 1 "  $ext"
done
debug 1 "to_update:"
for ext in "${to_update[@]}"; do
  debug 1 "  $ext"
done
debug 1 "skipped_already_installed:"
for ext in "${skipped_already_installed[@]}"; do
  debug 1 "  $ext"
done
debug 1 "skipped_not_found:"
for ext in "${skipped_not_found[@]}"; do
  debug 1 "  $ext"
done
debug 1 "to_remove:"
for ext in "${to_remove[@]}"; do
  debug 1 "  $ext"
done
# exit 0 # used for debugging

install_extension() {
  debug 1 "[install_extension] Installing extension: $1"
  ext="$1"
  publisher="${ext%%.*}"
  name="${ext#*.}"
  # Use code CLI directly instead of downloading VSIX
  install_output=$("$CODE_CMD" --install-extension "$publisher.$name" --force 2>&1)
  if echo "$install_output" | grep -qi 'success'; then
    debug 1 "[install_extension] Successfully installed $ext via code CLI"
    echo "$ext" >> "$TMPDIR/installed"
    return
  else
    debug 1 "[install_extension] Failed to install $ext via code CLI"
    echo "$ext (install failed)" >> "$TMPDIR/failed"
  fi
  # Fallback: try Open VSX
  debug 2 "[install_extension] Checking Open VSX for $publisher.$name"
  ovsx_vsix=$(download_openvsx_vsix "$publisher" "$name")
  if [ -n "$ovsx_vsix" ] && [ -f "$ovsx_vsix" ] && file "$ovsx_vsix" | grep -q 'Zip archive data'; then
    debug 2 "[install_extension] Installing from Open VSX VSIX: $ovsx_vsix"
    install_output=$("$CODE_CMD" --install-extension "$ovsx_vsix" --force 2>&1)
    if echo "$install_output" | grep -qi 'success'; then
      debug 1 "[install_extension] Successfully installed $ext from Open VSX"
      echo "$ext" >> "$TMPDIR/installed"
    else
      debug 1 "[install_extension] Failed to install $ext from Open VSX"
      echo "$ext (install failed)" >> "$TMPDIR/failed"
    fi
    return
  fi
  debug 1 "[install_extension] $ext not found on Marketplace or Open VSX"
  echo "$ext (not found)" >> "$TMPDIR/skipped_not_found"
}

# Add update_extension function
update_extension() {
  debug 1 "[update_extension] Updating extension: $1 from $2 to $3"
  ext="$1"
  oldver="$2"
  newver="$3"
  publisher="${ext%%.*}"
  name="${ext#*.}"
  # Use code CLI directly instead of downloading VSIX
  install_output=$("$CODE_CMD" --install-extension "$publisher.$name" --force 2>&1)
  if echo "$install_output" | grep -qi 'success'; then
    debug 1 "[update_extension] Successfully updated $ext via code CLI"
    echo "$ext ($oldver -> $newver)" >> "$TMPDIR/updated_exts"
    return
  else
    debug 1 "[update_extension] Failed to update $ext via code CLI"
    echo "$ext (update failed)" >> "$TMPDIR/failed"
  fi
  # Fallback: try Open VSX, but only if the version is different
  debug 2 "[update_extension] Checking Open VSX for $publisher.$name"
  ovsx_vsix=$(download_openvsx_vsix "$publisher" "$name")
  ovsx_version=$(curl -sS -A 'Mozilla/5.0' "https://open-vsx.org/api/$publisher/$name" | jq -r '.version // empty')
  if [ "$ovsx_version" = "$oldver" ]; then
    debug 1 "[update_extension] Open VSX version $ovsx_version is same as installed $oldver; marking as failed update."
    echo "$ext (update failed)" >> "$TMPDIR/failed"
    return
  fi
  if [ -n "$ovsx_vsix" ] && [ -f "$ovsx_vsix" ] && file "$ovsx_vsix" | grep -q 'Zip archive data'; then
    debug 2 "[update_extension] Installing from Open VSX VSIX: $ovsx_vsix"
    install_output=$("$CODE_CMD" --install-extension "$ovsx_vsix" --force 2>&1)
    if echo "$install_output" | grep -qi 'success'; then
      debug 1 "[update_extension] Successfully updated $ext from Open VSX"
      echo "$ext ($oldver -> $ovsx_version)" >> "$TMPDIR/updated_exts"
    else
      debug 1 "[update_extension] Failed to update $ext from Open VSX"
      echo "$ext (update failed)" >> "$TMPDIR/failed"
    fi
    return
  fi
  debug 1 "[update_extension] $ext not found on Marketplace or Open VSX"
  echo "$ext (update not found)" >> "$TMPDIR/skipped_not_found"
}

# remove an extension
remove_extension() {
  debug 1 "[remove_extension] Removing extension: $1"
  ext="$1"
  if "$CODE_CMD" --uninstall-extension "$ext" --force >/dev/null 2>&1; then
    echo "$ext" >> "$TMPDIR/removed_exts"
  else
    echo "$ext (remove failed)" >> "$TMPDIR/failed"
  fi
}

debug 1 "Installing/Updating/Removing all extensions (in parallel)..."
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
# Now run removals, also in parallel
for ext in "${to_remove[@]}"; do
  remove_extension "$ext" &
  pids+=("$!")
  if (( ${#pids[@]} >= CONCURRENCY )); then
    wait "${pids[0]}"
    pids=("${pids[@]:1}")
  fi
done
# Wait for all install/update/remove jobs to finish
for pid in "${pids[@]}"; do
  wait "$pid"
done

# Aggregate final results from temp files into arrays for summary
installed=(); [ -f "$TMPDIR/installed" ] && mapfile -t installed < "$TMPDIR/installed"
skipped_already_installed=(); [ -f "$TMPDIR/skipped_already_installed" ] && mapfile -t skipped_already_installed < "$TMPDIR/skipped_already_installed"
skipped_not_found=(); [ -f "$TMPDIR/skipped_not_found" ] && mapfile -t skipped_not_found < "$TMPDIR/skipped_not_found"
failed=(); [ -f "$TMPDIR/failed" ] && mapfile -t failed < "$TMPDIR/failed"
removed_exts=(); [ -f "$TMPDIR/removed_exts" ] && mapfile -t removed_exts < "$TMPDIR/removed_exts"
updated_exts=(); [ -f "$TMPDIR/updated_exts" ] && mapfile -t updated_exts < "$TMPDIR/updated_exts"

# Cleanup
rm -rf "$TMPDIR"

