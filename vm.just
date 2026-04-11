# NixOS VM Testing - Direct nixos-rebuild build-vm workflow
# Simple commands for iterative configuration testing without ISO intermediaries

# Auto-detect current host for VM testing
default_vm_host := `scripts/get-flake-target.sh`

# Build and run a NixOS VM for testing configurations
# Usage: just vm [host]
vm host=default_vm_host:
    @echo "🔧 Building VM for {{host}}..."
    nixos-rebuild build-vm --flake .#{{host}} --print-build-logs
    @echo "🚀 Starting VM for {{host}}..."
    sudo ./result/bin/run-{{host}}-vm

# Build VM without running (useful for CI or pre-building)
# Usage: just vm-build [host]
vm-build host=default_vm_host:
    @echo "🔧 Building VM for {{host}}..."
    nixos-rebuild build-vm --flake .#{{host}} --print-build-logs
    @echo "✅ VM built successfully. Run with: ./result/bin/run-{{host}}-vm"

# Run a previously built VM
# Usage: just vm-run [host]
vm-run host=default_vm_host:
    @test -f ./result/bin/run-{{host}}-vm || (echo "❌ No VM found for {{host}}. Build first with: just vm-build {{host}}" && exit 1)
    @echo "🚀 Starting VM for {{host}}..."
    sudo ./result/bin/run-{{host}}-vm

# Clean up VM build artifacts
vm-clean:
    @echo "🧹 Cleaning VM artifacts..."
    rm -rf result result-*
    @echo "✅ VM artifacts cleaned"

# List all available VM configurations
vm-list:
    @echo "📋 Available VM configurations:"
    @nix eval .#nixosConfigurations --apply builtins.attrNames 2>/dev/null || echo "  - wsl\n  - merlin\n  - ganoslal\n  - spacedock"
