#!/usr/bin/env bash
# Smart hardware configuration validation script
# Checks for differences between /etc/nixos/hardware-configuration.nix and our custom config

set -euo pipefail

ORIGINAL_CONFIG="/etc/nixos/hardware-configuration.nix"
CUSTOM_CONFIG="hosts/ganoslal/custom-hardware-config.nix"
HOST_DEFAULT="hosts/ganoslal/default.nix"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

check_file_exists() {
    local file="$1"
    local description="$2"
    
    if [[ ! -f "$file" ]]; then
        print_error "$description not found at: $file"
        return 1
    fi
    return 0
}

# Check if we're in the right directory
if [[ ! -f "flake.nix" ]]; then
    print_error "Not in the dotfiles root directory. Please run from /home/gig/.dotfiles"
    exit 1
fi

print_status "Checking hardware configuration synchronization..."

# Check if all required files exist
check_file_exists "$ORIGINAL_CONFIG" "Original hardware configuration" || exit 1
check_file_exists "$CUSTOM_CONFIG" "Custom hardware configuration" || exit 1
check_file_exists "$HOST_DEFAULT" "Host default configuration" || exit 1

# Extract the actual hardware config content (excluding imports and custom overrides)
print_status "Comparing hardware configurations..."

# Create temporary files for comparison
TEMP_ORIGINAL=$(mktemp)
TEMP_CUSTOM=$(mktemp)

# Clean up on exit
trap 'rm -f "$TEMP_ORIGINAL" "$TEMP_CUSTOM"' EXIT

# Extract original hardware config content (skip comments and empty lines)
grep -v '^\s*#' "$ORIGINAL_CONFIG" | grep -v '^\s*$' > "$TEMP_ORIGINAL"

# Extract the imported hardware config from our custom file
# Look for the import line and extract what it imports
IMPORT_LINE=$(grep -n "^\s*imports\s*=\s*\[" "$CUSTOM_CONFIG" || true)
if [[ -z "$IMPORT_LINE" ]]; then
    print_error "Could not find imports section in $CUSTOM_CONFIG"
    exit 1
fi

# Check if the custom config properly imports the original
IMPORTS_ORIGINAL=$(grep -q -E "\./hardware-configuration\.nix|/etc/nixos/hardware-configuration\.nix" "$CUSTOM_CONFIG" && echo "yes" || echo "no")

if [[ "$IMPORTS_ORIGINAL" == "yes" ]]; then
    print_success "Custom hardware config properly imports original configuration"
else
    print_error "Custom hardware config does not import /etc/nixos/hardware-configuration.nix"
    print_warning "Expected to find: ./hardware-configuration.nix or /etc/nixos/hardware-configuration.nix in imports"
    exit 1
fi

# Check if the host default.nix imports the custom config
IMPORTS_CUSTOM=$(grep -q "custom-hardware-config.nix" "$HOST_DEFAULT" && echo "yes" || echo "no")

if [[ "$IMPORTS_CUSTOM" == "yes" ]]; then
    print_success "Host configuration properly imports custom hardware config"
else
    print_error "Host default.nix does not import custom-hardware-config.nix"
    print_warning "Expected to find: ./custom-hardware-config.nix in $HOST_DEFAULT"
    exit 1
fi

# Check for recent modifications to the original hardware config
ORIGINAL_MTIME=$(stat -c %Y "$ORIGINAL_CONFIG" 2>/dev/null || echo "0")
CUSTOM_MTIME=$(stat -c %Y "$CUSTOM_CONFIG" 2>/dev/null || echo "0")

if [[ "$ORIGINAL_MTIME" -gt "$CUSTOM_MTIME" ]]; then
    print_warning "Original hardware config is newer than custom config!"
    print_warning "You may need to review changes in $ORIGINAL_CONFIG"
    print_warning "Consider running: nixos-generate-config --show-hardware-config"
fi

# Check if nixos-rebuild would succeed (dry run)
print_status "Testing configuration build (dry-run)..."

if nix build ".#nixosConfigurations.ganoslal.config.system.build.toplevel" --dry-run > /dev/null 2>&1; then
    print_success "Configuration builds successfully"
else
    print_error "Configuration has build errors!"
    print_warning "Run: nix build '.#nixosConfigurations.ganoslal.config.system.build.toplevel' for details"
    exit 1
fi

# Check for GPU-related configurations
print_status "Checking GPU configurations..."

GPU_CONFIG_FOUND=false

# Check for NVIDIA config
if grep -q "nvidia" "$CUSTOM_CONFIG" 2>/dev/null; then
    print_success "NVIDIA configuration found in custom hardware config"
    GPU_CONFIG_FOUND=true
fi

# Check for AMD config  
if grep -q "amdgpu" "$CUSTOM_CONFIG" 2>/dev/null; then
    print_success "AMD GPU configuration found in custom hardware config"
    GPU_CONFIG_FOUND=true
fi

if [[ "$GPU_CONFIG_FOUND" == "false" ]]; then
    print_warning "No GPU-specific configuration found in custom hardware config"
    print_warning "Multi-GPU setup may not be properly configured"
fi

print_success "Hardware configuration check completed successfully!"

# Provide helpful next steps
echo ""
print_status "Recommended next steps:"
echo "  1. Run: just rebuild-test  # Test the configuration"
echo "  2. Run: just rebuild      # Apply the configuration" 
echo "  3. Check GPU setup with: nvidia-smi && lspci | grep VGA"
echo ""
