# OpenCode Configuration Guide

## Overview

This guide covers the complete OpenCode configuration implemented in this NixOS dotfiles repository, including MCP server integration, custom commands, theming, and usage strategies.

## Configuration Location

Primary configuration: `home/gig/common/core/opencode.nix`

## Current Configuration Summary

### Theme
- **Active**: `gruvbox` (built-in dark theme)
- **Alternative**: Custom LCARS theme available but gruvbox preferred for readability

### MCP Server Integration

Four MCP servers configured for enhanced capabilities:

```nix
mcpServers = {
  wikipedia = {
    command = "npx";
    args = [ "rudra-ravi/wikipedia-mcp" ];
    # Research tool: Get comprehensive Wikipedia article information
  };
  
  arxiv = {
    command = "uvx"; 
    args = [ "blazickjp/arxiv-mcp-server" ];
    # Academic research: Search and access ArXiv papers
  };
  
  context7 = {
    command = "npx";
    args = [ "-y" "@context7/mcp-server" ];
    env = { CONTEXT7_API_KEY = "demo"; };
    # Documentation search across multiple sources
  };
  
  github_grep = {
    command = "npx";
    args = [ "-y" "@mcp/server-github" ];
    env = { GITHUB_TOKEN = "\${GITHUB_TOKEN}"; };
    # Code search across GitHub repositories
  };
};
```

### Custom Commands

Flake-focused commands for NixOS development:

```nix
customCommands = [
  { name = "/check"; description = "Run nix flake check"; command = "nix flake check --keep-going"; }
  { name = "/build"; description = "Build current flake"; command = "nix build"; }
  { name = "/update"; description = "Update flake inputs"; command = "nix flake update"; }
  { name = "/show"; description = "Show flake info"; command = "nix flake show"; }
  { name = "/develop"; description = "Enter dev shell"; command = "nix develop"; }
];
```

### TUI Settings

Optimized for performance and usability:

```nix
tui = {
  scrollAcceleration = true;  # Faster scrolling
  autoRunBashCommands = true; # Allow bash execution with user caution
};
```

## Usage Strategies

### When to Use Agents vs Subagents vs Commands

#### Built-in Agents
- **Switch with**: `Tab` key
- **Primary agents**: `build` and `plan` (built-in)
- **Use for**: Complex multi-step tasks requiring planning and execution

#### Custom Commands
- **Access with**: `/` prefix (e.g., `/check`, `/build`)
- **Use for**: Quick, single-purpose flake operations
- **Best practice**: Use these over manual nix commands for consistency

#### MCP Servers
- **Access via**: OpenCode's natural conversation flow
- **Wikipedia**: "Can you research [topic] on Wikipedia?"
- **ArXiv**: "Find papers about [academic topic]"
- **Context7**: "Search documentation for [technology]"
- **GitHub Grep**: "Find code examples of [pattern] on GitHub"

### Development Workflow

1. **Start session**: Use `/show` to understand current flake state
2. **Make changes**: Edit configuration files
3. **Validate**: Use `/check` to verify syntax and dependencies
4. **Build**: Use `/build` for specific targets
5. **Update**: Use `/update` when refreshing dependencies
6. **Research**: Leverage MCP servers for documentation and examples

### Safety and Security

#### Bash Command Execution
- **Setting**: `autoRunBashCommands = true`
- **Safety model**: User caution over restrictive permissions
- **Rationale**: Experienced NixOS users can handle responsibility; restrictions would limit productivity

#### MCP Server Security
- **Wikipedia/ArXiv**: No API keys required (read-only)
- **Context7**: Demo key for testing (upgrade for production use)
- **GitHub**: Uses environment variable for token security

## Configuration Management

### Dependencies
All required packages already available in `home/gig/home.nix`:
- `nodejs_22`: For NPM-based MCP servers
- `python312`: For Python MCP servers  
- `uv`: For modern Python package management

### Applying Changes
```bash
# Rebuild home-manager configuration
just home

# Or manually:
scripts/home-manager-flake-rebuild.sh
```

### Testing MCP Integration
After applying configuration:

1. Start OpenCode
2. Test Wikipedia: "Research quantum computing on Wikipedia"
3. Test ArXiv: "Find recent papers on machine learning"
4. Test Context7: "Search for NixOS documentation"
5. Test GitHub: "Find examples of flake.nix files"

## Advanced Customization

### Adding New MCP Servers

1. Research available servers at [MCP Directory](https://github.com/modelcontextprotocol)
2. Add to `mcpServers` attribute set in `opencode.nix`
3. Include required dependencies in `home.nix` if needed
4. Test functionality after rebuild

### Creating Custom Commands

Add to `customCommands` list:
```nix
{ name = "/new-command"; description = "Description"; command = "your-command-here"; }
```

### Theme Customization

Current options:
- `gruvbox` (current, recommended)
- `default` (OpenCode default)
- Custom themes (create in themes directory)

## Troubleshooting

### MCP Server Issues
- **Check dependencies**: Ensure Node.js/Python packages available
- **Verify commands**: Test MCP commands manually in terminal
- **Review logs**: Check OpenCode logs for connection errors

### Command Failures
- **Flake commands**: Ensure you're in a valid flake directory
- **Permissions**: Verify file/directory access rights
- **Dependencies**: Check that required tools are installed

### Performance Issues
- **Scroll acceleration**: Already enabled for faster navigation
- **MCP timeouts**: Some servers may be slow; consider alternatives

## Future Enhancements

### Potential MCP Additions
- **Uptime monitoring**: For infrastructure management
- **Database access**: For development workflows
- **Cloud APIs**: For deployment automation

### Command Expansions
- **Testing commands**: `/test`, `/test-vm`
- **Deployment commands**: `/deploy`, `/stage`
- **Maintenance commands**: `/clean`, `/optimize`

### Theme Development
- **Custom themes**: Based on specific color preferences
- **Dynamic themes**: Switching based on time/context
- **Accessibility themes**: High contrast options

## Best Practices

### Daily Usage
1. Start with `/show` to understand current state
2. Use MCP servers for research before implementing
3. Test changes with `/check` before building
4. Leverage custom commands over manual typing

### Maintenance
1. Regular `/update` to keep dependencies current
2. Monitor MCP server functionality
3. Review and optimize custom commands periodically
4. Update this guide when making configuration changes

### Security
1. Rotate GitHub tokens periodically
2. Monitor MCP server network activity
3. Be cautious with `autoRunBashCommands` setting
4. Keep dependencies updated for security patches

---

This configuration provides a powerful, integrated development environment optimized for NixOS flake development with enhanced research capabilities through MCP server integration.
