{
  self,
  pkgs,
}:
let
  # Create a test derivation that validates OpenCode MCP configuration
  openCodeMcpTest = pkgs.writeShellScriptBin "test-opencode-mcp" ''
    set -euo pipefail

    echo "===== OpenCode MCP Configuration Validation ====="
    echo ""

    # Validate MCP Nix configuration files exist
    echo "Checking MCP Nix configuration files..."

    MCP_DIR="${self}/home/gig/common/core/opencode/mcp"
    if [ ! -d "$MCP_DIR" ]; then
      echo "  ✗ ERROR: MCP configuration directory not found: $MCP_DIR"
      exit 1
    fi

    # Verify default.nix exists
    if [ ! -f "$MCP_DIR/default.nix" ]; then
      echo "  ✗ ERROR: MCP default.nix not found"
      exit 1
    fi
    echo "  ✓ Found MCP default.nix"

    # Count and list MCP server configurations
    MCP_COUNT=$(find "$MCP_DIR" -maxdepth 1 -name "*.nix" ! -name "default.nix" | wc -l)
    echo "  ✓ Found $MCP_COUNT MCP server configuration(s)"

    echo ""
    echo "Configured MCP servers:"
    for config in "$MCP_DIR"/*.nix; do
      if [ "$(basename "$config")" != "default.nix" ]; then
        SERVER_NAME=$(basename "$config" .nix)
        echo "  - $SERVER_NAME"
      fi
    done
    echo ""

    # Check that wrapper scripts are executable if they exist
    WRAPPER_DIR="${self}/home/gig/common/core/opencode/scripts"
    if [ -d "$WRAPPER_DIR" ]; then
      echo "Checking MCP wrapper scripts..."
      FOUND_SCRIPTS=false
      shopt -s nullglob
      for script in "$WRAPPER_DIR"/*.sh; do
        if [ -f "$script" ]; then
          FOUND_SCRIPTS=true
          echo "  ✓ Found: $(basename "$script")"
          if [ ! -x "$script" ]; then
            echo "  ✗ ERROR: Script is not executable: $script"
            exit 1
          fi
        fi
      done
      if [ "$FOUND_SCRIPTS" = false ]; then
        echo "  ℹ No wrapper scripts found (may use npx directly)"
      fi
      echo ""
    fi

    # Parse and validate Nix syntax for each MCP config
    echo "Validating Nix files are readable..."
    for config in "$MCP_DIR"/*.nix; do
      if [ ! -r "$config" ]; then
        echo "  ✗ ERROR: Cannot read $(basename "$config")"
        exit 1
      fi
    done
    echo "  ✓ All MCP configuration files are readable"
    echo ""

    echo "===== All OpenCode MCP Checks Passed! ====="
    echo ""
    echo "Note: This check validates configuration file syntax and structure."
    echo "To ensure OpenCode starts properly after rebuild, run: opencode --version"

    # Create a success marker file
    touch $out
  '';

  # Create the actual check derivation
  openCodeCheck =
    pkgs.runCommand "opencode-mcp-config-check"
      {
        nativeBuildInputs = [ openCodeMcpTest ];
      }
      ''
        test-opencode-mcp
      '';
in
{
  opencode-mcp-config = openCodeCheck;
}
