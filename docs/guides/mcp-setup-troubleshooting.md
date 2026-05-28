# MCP Servers Setup and Troubleshooting Guide

**Last Updated**: 2026-05-28  
**Agent**: Lt. Commander Data

## Overview

This document provides comprehensive information about the Model Context Protocol (MCP) servers configured in OpenCode, including setup instructions, troubleshooting steps, and available tools.

## Current MCP Server Configuration

### 1. Wikipedia (`wikipedia-mcp`)
- **Type**: Local (npx)
- **Package**: `wikipedia-mcp` (v1.0.3)
- **Description**: Search and retrieve Wikipedia articles via REST API
- **Auth Required**: No
- **Status**: ✅ Working (Fixed 2026-05-28)

**Available Tools**:
- `wikipedia_getPage` - Retrieve full Wikipedia article content
- `wikipedia_findPage` - Search for Wikipedia pages
- `wikipedia_onThisDay` - Get historical events for a specific date
- `wikipedia_getImagesForPage` - Get images from Wikipedia article

**Common Issues**:
- **Previous package** `pipeworx-mcp-wikipedia` was broken (no bin entry)
- **Solution**: Switched to `wikipedia-mcp` which has proper executable

### 2. DeepWiki
- **Type**: Remote (HTTP)
- **URL**: https://mcp.deepwiki.com/mcp
- **Description**: Repository documentation and history research
- **Auth Required**: No
- **Status**: ✅ Working

**Available Tools**:
- `deepwiki_ask_question` - Ask questions about repository documentation
- `deepwiki_read_wiki_contents` - Read wiki/documentation contents
- `deepwiki_read_wiki_structure` - Get documentation structure

### 3. Internet Search (`@nachoretro/internetsearch`)
- **Type**: Local (npx)
- **Package**: `@nachoretro/internetsearch` (v1.1.2)
- **Description**: Multi-engine web search (DuckDuckGo, Brave), RSS, YouTube transcripts, metadata extraction
- **Auth Required**: No (DuckDuckGo), Optional (Brave API key for better results)
- **Status**: ✅ Working (Replaced broken mcp-duckduckgo)

**Features**:
- DuckDuckGo search (no API key needed)
- Brave search (with optional API key)
- RSS feed reading
- YouTube transcript extraction
- OpenGraph metadata extraction
- Content scraping and extraction

**Common Issues**:
- **Previous package** `mcp-duckduckgo` was a dynamically-linked binary that can't run on NixOS
- **Solution**: Switched to `@nachoretro/internetsearch` which is Node-based and works natively

### 4. GitHub (`@modelcontextprotocol/server-github`)
- **Type**: Local (npx)
- **Package**: `@modelcontextprotocol/server-github`
- **Description**: GitHub repository and issue management
- **Auth Required**: Yes (GITHUB_TOKEN)
- **Status**: ⚠️ Needs Token Configuration

**Available Tools**: 26 tools including
- Repository operations (create, fork, search)
- Issue management (create, update, list, comment)
- Pull request operations (create, review, merge, update)
- File operations (get contents, create/update files)
- Commit and branch management

**Setup Required**:
1. **Create GitHub Personal Access Token**:
   ```bash
   # Go to: https://github.com/settings/tokens
   # Or use GitHub CLI:
   gh auth login
   ```

2. **Set environment variable**:
   ```bash
   # Option 1: Add to Nushell config (~/.config/nushell/env.nu)
   $env.GITHUB_TOKEN = "ghp_your_token_here"
   
   # Option 2: Add to home.nix sessionVariables (not recommended for secrets)
   # Option 3: Use SOPS secrets (recommended for production)
   ```

3. **For SOPS secrets** (recommended):
   ```nix
   # Add to home/gig/common/core/sops.nix
   sops.secrets."github/personal-access-token" = {
     path = "/home/gig/.config/github/token";
   };
   
   # Then in home.nix:
   home.sessionVariables = {
     GITHUB_TOKEN = "$(cat ~/.config/github/token 2>/dev/null || echo '')";
   };
   ```

**Common Issues**:
- "Method not found" errors for resources/prompts - **Normal**, these are optional MCP features
- Authentication failures - Check GITHUB_TOKEN is set and valid

## Troubleshooting

### General MCP Issues

**Check MCP server logs**:
```bash
ls -lt ~/.local/share/opencode/log/ | head -5
tail -100 ~/.local/share/opencode/log/$(ls -t ~/.local/share/opencode/log/ | head -1) | grep -i mcp
```

**Test MCP package manually**:
```bash
npx -y wikipedia-mcp            # Should start without error
npx -y @nachoretro/internetsearch  # Should show "running on stdio"
npx -y @modelcontextprotocol/server-github  # Needs GITHUB_TOKEN
```

**Clear NPM cache** (fixes most npx issues):
```bash
rm -rf ~/.npm/_npx
npm cache clean --force
```

### NixOS-Specific Issues

**Dynamically-linked binaries**:
- Error: "Could not start dynamically linked executable"
- **Solution**: Use Node-based packages instead of native binaries
- Example: `@nachoretro/internetsearch` instead of `mcp-duckduckgo`

**Missing node_modules**:
- npx automatically downloads packages to ~/.npm/_npx/
- If corrupted, delete and retry: `rm -rf ~/.npm/_npx`

### Environment Variables

**Check if environment variables are set**:
```bash
# In Nushell:
$env.GITHUB_TOKEN
echo $env.GITHUB_TOKEN

# In Bash:
echo $GITHUB_TOKEN
```

**Environment not loading**:
1. Rebuild home-manager: `just home`
2. Restart shell or source config
3. Check sessionVariables in home.nix

## Configuration Files

- **MCP Config**: `~/.dotfiles/home/gig/common/core/opencode.nix` (lines 56-132)
- **Generated Config**: `~/.config/opencode/config.json` (read-only symlink)
- **Session Variables**: `~/.dotfiles/home/gig/home.nix` (line 37)
- **Nushell Env**: `~/.config/nushell/env.nu` (runtime environment)

## Adding New MCP Servers

1. **Test package works**:
   ```bash
   npx -y <package-name>
   ```

2. **Add to opencode.nix**:
   ```nix
   mcp = {
     servername = {
       type = "local";  # or "remote"
       command = [ "npx" "-y" "package-name" ];
       enabled = true;
       timeout = 15000;  # milliseconds
       env = {
         # Optional environment variables
         API_KEY = "{env:MY_API_KEY}";
       };
     };
   };
   ```

3. **Rebuild and test**:
   ```bash
   just home  # Rebuild home-manager
   # Check logs after starting opencode
   ```

## Quick Fix Checklist

When MCP servers aren't working:

- [ ] Clear NPM cache: `rm -rf ~/.npm/_npx && npm cache clean --force`
- [ ] Check OpenCode logs: `~/.local/share/opencode/log/`
- [ ] Test package manually: `npx -y <package-name>`
- [ ] Verify environment variables are set
- [ ] Rebuild home-manager: `just home`
- [ ] Restart OpenCode session

## References

- [Model Context Protocol Docs](https://modelcontextprotocol.io)
- [OpenCode MCP Documentation](https://opencode.ai/docs/mcp)
- [NPM Package Search](https://www.npmjs.com/search?q=mcp)
- [MCP Server Registry](https://github.com/modelcontextprotocol/servers)

---

**Maintenance Notes**:
- Check for package updates periodically
- Test MCP servers after major home-manager rebuilds
- Update this document when adding/removing MCP servers
- Monitor OpenCode logs for deprecation warnings
