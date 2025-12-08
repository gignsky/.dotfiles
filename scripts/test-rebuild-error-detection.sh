#!/usr/bin/env bash

# Test script to verify rebuild error detection works properly

echo "🧪 Testing rebuild script error detection..."

# Test 1: Command that succeeds - tee should not mask success
echo "Test 1: Testing successful command with tee pipeline"
set -o pipefail
if echo "success" 2>&1 | tee /tmp/test-success.log; then
    echo "✅ Success correctly detected"
else
    echo "❌ Success incorrectly reported as failure"
fi

# Test 2: Command that fails - tee should not mask failure  
echo "Test 2: Testing failing command with tee pipeline"
set -o pipefail
if false 2>&1 | tee /tmp/test-failure.log; then
    echo "❌ Failure incorrectly reported as success"
else
    echo "✅ Failure correctly detected"
fi

# Test 3: Test PIPESTATUS array
echo "Test 3: Testing PIPESTATUS array for precise exit code capture"
set -o pipefail
false | tee /tmp/test-pipestatus.log
first_cmd_exit=${PIPESTATUS[0]}
tee_exit=${PIPESTATUS[1]}

echo "  - First command exit code: $first_cmd_exit"
echo "  - Tee exit code: $tee_exit"

if [ "$first_cmd_exit" -eq 1 ] && [ "$tee_exit" -eq 0 ]; then
    echo "✅ PIPESTATUS correctly captures individual command exit codes"
else
    echo "❌ PIPESTATUS not working as expected"
fi

# Test 4: Simulate nixos-rebuild failure
echo "Test 4: Testing simulated nixos-rebuild failure"
set -o pipefail

# Simulate the problematic scenario from the original script
simulate_nixos_rebuild() {
    echo "building the system configuration..."
    echo "error: attribute 'guid' missing"
    return 1  # This simulates nixos-rebuild failing
}

output_file=$(mktemp)
if simulate_nixos_rebuild 2>&1 | tee "$output_file"; then
    nixos_rebuild_exit_code=${PIPESTATUS[0]}
else
    nixos_rebuild_exit_code=${PIPESTATUS[0]}
fi

if [ "$nixos_rebuild_exit_code" -eq 0 ]; then
    echo "❌ Simulated failure incorrectly reported as success"
else
    echo "✅ Simulated failure correctly detected (exit code: $nixos_rebuild_exit_code)"
fi

# Show the captured output
echo "  - Captured output:"
cat "$output_file" | sed 's/^/    /'

# Cleanup
rm -f /tmp/test-*.log "$output_file"

echo ""
echo "🏁 Error detection testing complete!"
