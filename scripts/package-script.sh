#!/usr/bin/env bash
# Interactive script packager with fzf selection and OpenCode test generation
# Converts shell scripts to Nix packages with dependency injection and smart test generation

set -euo pipefail

SCRIPTS_DIR="scripts"
SCRIPTS_NIX="pkgs/scripts.nix"
PKGS_DEFAULT="pkgs/default.nix"
JUSTFILE="justfile"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${MAGENTA}[STEP]${NC} $1"
}

print_opencode() {
    echo -e "${CYAN}[OPENCODE]${NC} $1"
}

# Check if we're in the right directory
if [[ ! -f "flake.nix" ]]; then
    print_error "Not in the dotfiles root directory. Please run from the project root"
    exit 1
fi

# Check for required tools
for tool in fzf nix git; do
    if ! command -v "$tool" > /dev/null; then
        print_error "Required tool '$tool' not found in PATH"
        exit 1
    fi
done

print_step "Scanning for shell scripts in $SCRIPTS_DIR directory..."

# Find all .sh files in scripts directory
if [[ ! -d "$SCRIPTS_DIR" ]]; then
    print_error "Scripts directory '$SCRIPTS_DIR' not found"
    exit 1
fi

SCRIPT_FILES=($(find "$SCRIPTS_DIR" -name "*.sh" -type f | sort))

if [[ ${#SCRIPT_FILES[@]} -eq 0 ]]; then
    print_warning "No .sh files found in $SCRIPTS_DIR directory"
    exit 1
fi

print_info "Found ${#SCRIPT_FILES[@]} shell script(s)"

# Use fzf to select a script
print_step "Select a script to package (use fzf)..."
SELECTED_SCRIPT=$(printf '%s\n' "${SCRIPT_FILES[@]}" | fzf \
    --prompt="Select script to package: " \
    --preview="bat --color=always --style=header,grid --line-range :50 {}" \
    --preview-window=right:60%:wrap \
    --height=60% \
    --border \
    --header="Select a shell script to convert to a Nix package")

if [[ -z "$SELECTED_SCRIPT" ]]; then
    print_warning "No script selected. Exiting."
    exit 0
fi

print_success "Selected script: $SELECTED_SCRIPT"

# Extract script name without .sh extension
SCRIPT_NAME=$(basename "$SELECTED_SCRIPT" .sh)
PACKAGE_NAME=$(echo "$SCRIPT_NAME" | tr '_' '-')  # Convert underscores to hyphens for Nix

print_info "Package name: $PACKAGE_NAME"

# Check if script is already packaged
print_step "Checking if script is already packaged..."

if grep -q "\"$PACKAGE_NAME\"" "$SCRIPTS_NIX" 2>/dev/null; then
    print_warning "Script '$PACKAGE_NAME' is already packaged in $SCRIPTS_NIX"
    
    read -p "Do you want to update the existing package? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Exiting without changes"
        exit 0
    fi
    
    UPDATE_EXISTING=true
else
    UPDATE_EXISTING=false
    print_success "Script is not yet packaged"
fi

# Analyze script dependencies
print_step "Analyzing script dependencies..."

declare -a DETECTED_DEPS=()

# Common dependency mappings
declare -A DEP_MAP=(
    ["git"]="git"
    ["nix"]="nix"
    ["nixos-rebuild"]="nixos-rebuild"
    ["home-manager"]="home-manager"
    ["grep"]="gnugrep"
    ["awk"]="gawk" 
    ["sed"]="gnused"
    ["tree"]="tree"
    ["curl"]="curl"
    ["wget"]="wget"
    ["jq"]="jq"
    ["systemctl"]="systemd"
    ["hostname"]="hostname"
    ["lspci"]="pciutils"
    ["lsusb"]="usbutils"
    ["qemu"]="qemu"
    ["pre-commit"]="pre-commit"
    ["age"]="age"
    ["ssh-keygen"]="openssh"
    ["gpg"]="gnupg"
    ["tar"]="gnutar"
    ["unzip"]="unzip"
    ["zip"]="zip"
    ["rsync"]="rsync"
    ["stat"]="coreutils"
    ["ls"]="coreutils"
    ["mkdir"]="coreutils"
    ["rm"]="coreutils"
    ["cp"]="coreutils"
    ["mv"]="coreutils"
    ["cat"]="coreutils"
    ["head"]="coreutils"
    ["tail"]="coreutils"
    ["sort"]="coreutils"
    ["wc"]="coreutils"
    ["tr"]="coreutils"
)

# Always include bash as dependency
DETECTED_DEPS+=("bash")

# Scan script for tool usage
while IFS= read -r line; do
    # Skip comments and empty lines
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// }" ]] && continue
    
    # Look for command usage patterns
    for cmd in "${!DEP_MAP[@]}"; do
        if [[ "$line" =~ [^a-zA-Z]${cmd}[^a-zA-Z] ]] || [[ "$line" =~ ^${cmd}[^a-zA-Z] ]]; then
            dep="${DEP_MAP[$cmd]}"
            if [[ ! " ${DETECTED_DEPS[*]} " =~ " $dep " ]]; then
                DETECTED_DEPS+=("$dep")
            fi
        fi
    done
done < "$SELECTED_SCRIPT"

print_info "Detected dependencies: ${DETECTED_DEPS[*]}"

# Allow user to edit dependencies
read -p "Edit dependencies? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_step "Enter dependencies (space-separated, or press Enter to use detected):"
    echo "Detected: ${DETECTED_DEPS[*]}"
    read -r USER_DEPS
    if [[ -n "$USER_DEPS" ]]; then
        read -a DETECTED_DEPS <<< "$USER_DEPS"
    fi
fi

# Generate Nix dependencies list
NIX_DEPS=""
for dep in "${DETECTED_DEPS[@]}"; do
    if [[ -z "$NIX_DEPS" ]]; then
        NIX_DEPS="$dep"
    else
        NIX_DEPS="$NIX_DEPS\n        $dep"
    fi
done

# Generate script description
SCRIPT_DESCRIPTION=$(head -5 "$SELECTED_SCRIPT" | grep -E "^#.*" | head -1 | sed 's/^# *//' | sed 's/^#!//')
if [[ -z "$SCRIPT_DESCRIPTION" ]]; then
    SCRIPT_DESCRIPTION="A packaged shell script"
fi

print_info "Description: $SCRIPT_DESCRIPTION"

# Add package to scripts.nix
print_step "Adding package to $SCRIPTS_NIX..."

# Create the package entry
PACKAGE_ENTRY="    # $(echo "$SCRIPT_NAME" | tr '-' ' ' | tr '_' ' ')
    $PACKAGE_NAME = makeScriptPackage {
      name = \"$PACKAGE_NAME\";
      scriptPath = ../$SELECTED_SCRIPT;
      dependencies = with pkgs; [
        $NIX_DEPS
      ];
      description = \"$SCRIPT_DESCRIPTION\";
    };"

if [[ "$UPDATE_EXISTING" == "true" ]]; then
    # Update existing package (replace between package name and closing brace)
    print_info "Updating existing package entry..."
    # This is complex sed - for now just inform user to update manually
    print_warning "Please manually update the package entry in $SCRIPTS_NIX"
    print_info "Package entry to update:"
    echo "$PACKAGE_ENTRY"
else
    # Add new package before the closing brace of scripts object
    print_info "Adding new package entry..."
    
    # Find the line number of the last script entry
    LAST_SCRIPT_LINE=$(grep -n "makeScriptPackage" "$SCRIPTS_NIX" | tail -1 | cut -d: -f1)
    
    if [[ -n "$LAST_SCRIPT_LINE" ]]; then
        # Find the closing brace of the last script entry
        CLOSING_BRACE_LINE=$(tail -n +$((LAST_SCRIPT_LINE + 1)) "$SCRIPTS_NIX" | grep -n "};" | head -1 | cut -d: -f1)
        INSERTION_LINE=$((LAST_SCRIPT_LINE + CLOSING_BRACE_LINE + 1))
        
        # Insert the new package entry
        {
            head -n $((INSERTION_LINE - 1)) "$SCRIPTS_NIX"
            echo ""
            echo "$PACKAGE_ENTRY"
            tail -n +$INSERTION_LINE "$SCRIPTS_NIX"
        } > "${SCRIPTS_NIX}.tmp" && mv "${SCRIPTS_NIX}.tmp" "$SCRIPTS_NIX"
        
        print_success "Added package entry to $SCRIPTS_NIX"
    else
        print_warning "Could not find insertion point in $SCRIPTS_NIX"
        print_info "Please manually add this entry:"
        echo "$PACKAGE_ENTRY"
    fi
fi

# Add to pkgs/default.nix exports
print_step "Adding to package exports..."

# Check if already exported
if ! grep -q "$PACKAGE_NAME" "$PKGS_DEFAULT"; then
    # Find the inherit line and add our package
    sed -i "/inherit (scripts)/,/;/{
        /;/i\\
    $(echo "$PACKAGE_NAME" | tr '-' '_' | tr -d '\n')
    }" "$PKGS_DEFAULT"
    print_success "Added $PACKAGE_NAME to package exports"
else
    print_info "Package already exported"
fi

# Test that the flake builds
print_step "Testing flake build..."

if nix flake check --keep-going > /dev/null 2>&1; then
    print_success "Flake builds successfully"
else
    print_error "Flake build failed! Please check the configuration"
    print_info "Run: nix flake check --keep-going"
    exit 1
fi

# Test the packaged script
print_step "Testing packaged script..."

if nix run ".#$PACKAGE_NAME" --help > /dev/null 2>&1 || nix run ".#$PACKAGE_NAME" --version > /dev/null 2>&1 || timeout 5 nix run ".#$PACKAGE_NAME" > /dev/null 2>&1; then
    print_success "Packaged script executes successfully"
else
    print_warning "Could not test script execution (this may be normal)"
fi

# Add to justfile
print_step "Adding justfile command..."

JUST_COMMAND="# Run the $SCRIPT_NAME script
$PACKAGE_NAME:
\tnix run .#$PACKAGE_NAME"

if ! grep -q "^$PACKAGE_NAME:" "$JUSTFILE"; then
    echo "" >> "$JUSTFILE"
    echo "$JUST_COMMAND" >> "$JUSTFILE"
    print_success "Added justfile command: just $PACKAGE_NAME"
else
    print_info "Justfile command already exists"
fi

# Offer OpenCode test generation
print_step "OpenCode test generation..."

read -p "Generate passthru test with OpenCode? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_opencode "Launching OpenCode to generate comprehensive passthru test..."
    
    OPENCODE_PROMPT="Generate a comprehensive passthru test for the Nix-packaged script '$PACKAGE_NAME' located at '$SELECTED_SCRIPT'. 

The test should:
- Validate the script's core functionality and syntax  
- Check for proper error handling
- Ensure all dependencies are available
- Be suitable for use in the makeScriptPackage passthru.tests attribute

Return only the Nix test code that should replace the current basic test. The test should be in this format:

tests = {
  comprehensive = pkgs.runCommand \"$PACKAGE_NAME-test\" { 
    buildInputs = [ $PACKAGE_NAME ];
  } ''
    # Your test commands here
    # Should exit with code 0 on success
    echo \"Test passed\" > \$out
  '';
};

Focus on testing what the script actually does based on its content and purpose."

    if command -v opencode > /dev/null; then
        echo "Launching OpenCode..."
        opencode "$OPENCODE_PROMPT"
    else
        print_warning "OpenCode not found in PATH"
        print_info "Please run this command manually:"
        echo "opencode \"$OPENCODE_PROMPT\""
    fi
fi

# Final summary
print_step "Package Summary"
echo -e "${GREEN}✓${NC} Script packaged: ${CYAN}$SELECTED_SCRIPT${NC}"
echo -e "${GREEN}✓${NC} Package name: ${CYAN}$PACKAGE_NAME${NC}"
echo -e "${GREEN}✓${NC} Dependencies: ${CYAN}${DETECTED_DEPS[*]}${NC}"
echo -e "${GREEN}✓${NC} Usage: ${CYAN}nix run .#$PACKAGE_NAME${NC}"
echo -e "${GREEN}✓${NC} Justfile: ${CYAN}just $PACKAGE_NAME${NC}"

print_success "Script packaging complete!"

# Suggest next steps
echo ""
print_info "Next steps:"
echo "  1. Test the script: nix run .#$PACKAGE_NAME"
echo "  2. Use via justfile: just $PACKAGE_NAME"
echo "  3. Commit changes: git add . && git commit -m 'feat: package $SCRIPT_NAME script'"
echo "  4. Update passthru tests if generated by OpenCode"
echo ""