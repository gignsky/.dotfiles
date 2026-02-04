# OpenCode MCP Server Nix Packaging

## Objective
Package OpenCode MCP server dependencies in a way that encapsulates them entirely within Nix, rather than relying on runtime npx/uvx calls.

## Current State
- MCP servers currently run via `npx -y @shelm/wikipedia-mcp-server` (runtime download)
- Dependencies like nodejs_22 are installed globally in home.packages
- MCP servers are downloaded on-demand when OpenCode starts
- No Nix-level dependency tracking or reproducibility for MCP servers

## Desired State
- MCP server packages defined as proper Nix derivations
- Dependencies encapsulated within each MCP server package
- Full reproducibility - no runtime downloads
- Version pinning and dependency management via flake.lock
- Potential for custom MCP server configurations

## Implementation Ideas

### Option 1: Nix Wrapper Packages
Create Nix packages for each MCP server that bundles dependencies:
```nix
pkgs.wikipedia-mcp-server = pkgs.buildNpmPackage {
  pname = "wikipedia-mcp-server";
  version = "1.0.1";
  src = pkgs.fetchFromNpm { ... };
  # Bundle all dependencies
};
```

### Option 2: OpenCode Nix Module Extension
Extend the opencode home-manager module to handle MCP packaging:
```nix
programs.opencode.mcpServers = {
  wikipedia = {
    enable = true;
    package = pkgs.wikipedia-mcp-server;
  };
};
```

### Option 3: Flake-based MCP Server Inputs
Add MCP servers as flake inputs for maximum reproducibility:
```nix
inputs.wikipedia-mcp.url = "npm:@shelm/wikipedia-mcp-server/1.0.1";
```

## Benefits
- **Reproducibility**: Exact versions tracked in flake.lock
- **Offline capability**: No runtime npm/npx downloads required
- **Performance**: Pre-built packages, no cold-start downloads
- **Security**: Nix store verification, no untrusted runtime downloads
- **Consistency**: Same MCP server versions across all hosts

## Challenges
- NPM/Node.js packaging in Nix can be complex
- Need to handle MCP server updates gracefully
- Some MCP servers might have platform-specific dependencies
- Python-based MCP servers (uvx) would need similar treatment

## References
- Current OpenCode config: `home/gig/common/core/opencode.nix`
- MCP server list: https://github.com/modelcontextprotocol/servers
- Nix Node.js packaging: https://nixos.org/manual/nixpkgs/stable/#node.js

## Related Work
- Consider similar approach for other runtime-downloaded tools
- Could be a pattern for other dynamic dependency systems

---

**Created**: 2026-02-02  
**Status**: Planning / Future Enhancement  
**Priority**: Medium (quality-of-life improvement, not critical)
