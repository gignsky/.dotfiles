# MCP Server Fix Summary - 2026-05-28

**Agent**: Lt. Commander Data  
**Session**: Troubleshooting and fixing non-working MCP servers in OpenCode  
**Duration**: ~30 minutes  
**Status**: ✅ Resolved

## Issues Found

### 1. Wikipedia MCP Server - BROKEN
- **Package**: `pipeworx-mcp-wikipedia`
- **Error**: `npm error could not determine executable to run`
- **Root Cause**: Package missing proper `bin` entry in package.json
- **Impact**: Wikipedia search unavailable

### 2. DuckDuckGo MCP Server - INCOMPATIBLE
- **Package**: `mcp-duckduckgo`
- **Error**: `ENOTEMPTY: directory not empty` (NPM cache corruption) + Dynamic linking issues
- **Root Cause**: 
  1. Package is a dynamically-linked binary that can't run on NixOS
  2. NPM cache corruption causing installation failures
- **Impact**: Web search functionality unavailable

### 3. GitHub MCP Server - CONFIGURATION INCOMPLETE
- **Package**: `@modelcontextprotocol/server-github`
- **Error**: No errors, but GITHUB_TOKEN not set in environment
- **Root Cause**: `GITHUB_TOKEN` environment variable not configured
- **Impact**: GitHub tools won't work without authentication

### 4. DeepWiki MCP Server - WORKING ✅
- **Package**: Remote HTTP server
- **Status**: Connected successfully, no issues

## Solutions Implemented

### Fix #1: Replace Wikipedia Package
```nix
# BEFORE
wikipedia = {
  type = "local";
  command = [ "npx" "-y" "pipeworx-mcp-wikipedia" ];
  enabled = true;
  timeout = 10000;
};

# AFTER
wikipedia = {
  type = "local";
  command = [ "npx" "-y" "wikipedia-mcp" ];  # Working package with proper bin entry
  enabled = true;
  timeout = 10000;
};
```

**Testing**:
```bash
npm view wikipedia-mcp bin
# Output: { 'wikipedia-mcp': 'dist/index.js' }  ✅ Has bin entry

npx -y wikipedia-mcp
# Starts successfully ✅
```

### Fix #2: Replace DuckDuckGo with InternetSearch
```nix
# BEFORE
duckduckgo = {
  type = "local";
  command = [ "npx" "-y" "mcp-duckduckgo" ];  # Broken: dynamically-linked binary
  enabled = true;
  timeout = 15000;
};

# AFTER
internetsearch = {
  type = "local";
  command = [ "npx" "-y" "@nachoretro/internetsearch" ];  # Node-based, works on NixOS
  enabled = true;
  timeout = 15000;
};
```

**Advantages of `@nachoretro/internetsearch`**:
- ✅ Node-based (no dynamic linking issues)
- ✅ Multiple search engines: DuckDuckGo, Brave (with API key)
- ✅ Additional features: RSS feeds, YouTube transcripts, metadata extraction
- ✅ No API key required for basic DuckDuckGo search
- ✅ Actively maintained (v1.1.2, updated April 2026)

**Testing**:
```bash
npx -y @nachoretro/internetsearch
# Output: "InternetSearch MCP server running on stdio" ✅
```

### Fix #3: Add GITHUB_TOKEN Documentation
Updated `home.nix` with environment variable placeholder and documentation:

```nix
sessionVariables = {
  FLAKE = "$HOME/.dotfiles/.";
  SHELL = "nu";
  MANPAGER = "${pkgs.bat-extras.batman}/bin/batman";
  TERM = "wezterm";
  TERMINAL = "wezterm";
  # GitHub token for MCP servers (GitHub, DeepWiki, etc.)
  # Set this in your shell environment or use `gh auth token` from GitHub CLI
  # GITHUB_TOKEN = ""; # Uncomment and add your token, or set via shell profile
};
```

**User Action Required**:
Lord Gig needs to set GITHUB_TOKEN. Options:

1. **Add to Nushell env.nu** (Recommended for quick setup):
   ```nushell
   # In ~/.config/nushell/env.nu
   $env.GITHUB_TOKEN = "ghp_your_token_here"
   ```

2. **Use GitHub CLI**:
   ```bash
   gh auth login
   # Then in env.nu:
   $env.GITHUB_TOKEN = (gh auth token)
   ```

3. **Use SOPS secrets** (Recommended for production):
   ```nix
   # In home/gig/common/core/sops.nix
   sops.secrets."github/personal-access-token" = {
     path = "/home/gig/.config/github/token";
   };
   ```

### Fix #4: NPM Cache Cleanup
Cleared corrupted NPM cache that was causing ENOTEMPTY errors:

```bash
rm -rf ~/.npm/_npx
npm cache clean --force
```

## Files Modified

1. **`home/gig/common/core/opencode.nix`**
   - Line 63: Changed `pipeworx-mcp-wikipedia` → `wikipedia-mcp`
   - Lines 106-116: Changed `duckduckgo` → `internetsearch` with new package

2. **`home/gig/home.nix`**
   - Lines 37-43: Added GITHUB_TOKEN documentation in sessionVariables

3. **`docs/guides/mcp-setup-troubleshooting.md`** (NEW)
   - Comprehensive MCP server documentation
   - Setup instructions for each server
   - Troubleshooting guide
   - NixOS-specific notes

## Build Results

```bash
nix flake check
# ✅ All checks passed

just home
# ✅ Home-Manager rebuild successful
# Generation: 180 (20s) for merlin
```

## Current MCP Server Status

| Server | Package | Status | Notes |
|--------|---------|--------|-------|
| Wikipedia | `wikipedia-mcp` | ✅ Working | Fixed package |
| InternetSearch | `@nachoretro/internetsearch` | ✅ Working | Replaced DuckDuckGo |
| DeepWiki | Remote HTTP | ✅ Working | No changes needed |
| GitHub | `@modelcontextprotocol/server-github` | ⚠️ Needs Token | Waiting for GITHUB_TOKEN |

## Next Steps for User

1. **Set GITHUB_TOKEN environment variable** (see Fix #3 above)
2. **Restart OpenCode** to pick up new MCP server configurations
3. **Test MCP tools** in a new OpenCode session
4. **Optional**: Create GitHub Personal Access Token if not already done:
   - Visit: https://github.com/settings/tokens
   - Create classic token with `repo`, `read:user`, `read:org` scopes

## Technical Notes

### Why `mcp-duckduckgo` Failed on NixOS
The `mcp-duckduckgo` package ships a pre-compiled binary (`bin/duckduckgo-mcp`) that is dynamically linked against glibc. NixOS uses a different filesystem structure and can't run such binaries without patching them with `patchelf` or using FHS environments.

Error encountered:
```
Could not start dynamically linked executable: /home/gig/.npm/_npx/.../bin/duckduckgo-mcp
NixOS cannot run dynamically linked executables intended for generic linux environments
```

**Solution**: Use Node.js-based MCP servers that run through the Node runtime, which is properly configured in NixOS.

### Alternative Web Search MCP Servers Considered

1. **`@brave/brave-search-mcp-server`**
   - ❌ Rejected: Requires Brave API key (not free)
   - Pro: High-quality search results
   - Con: Not zero-configuration

2. **`@nachoretro/internetsearch`** (CHOSEN)
   - ✅ Selected: Free, multi-engine, feature-rich
   - Pro: DuckDuckGo works without API key
   - Pro: Extra features (RSS, YouTube, metadata)
   - Pro: Pure Node.js, NixOS compatible

3. **`@perplexity-ai/mcp-server`**
   - ❌ Rejected: Requires Perplexity API key (paid)
   - Pro: AI-powered research capabilities

## Lessons Learned

1. **Always check package bin entries** before adding MCP servers
   - Use: `npm view <package> bin` to verify
   
2. **Avoid dynamically-linked binaries in NixOS**
   - Prefer Node.js/Python-based packages
   - Check for "Could not start dynamically linked executable" in logs

3. **Test MCP packages manually before configuration**
   - Run: `npx -y <package>` to verify it works
   - Check for immediate errors or proper startup

4. **Document environment variable requirements**
   - MCP servers often need API keys/tokens
   - Add comments in config for user setup

5. **Monitor OpenCode logs for MCP issues**
   - Location: `~/.local/share/opencode/log/`
   - Look for: `service=mcp` lines with ERROR level

## References

- [Wikipedia MCP Package](https://www.npmjs.com/package/wikipedia-mcp)
- [InternetSearch MCP Package](https://www.npmjs.com/package/@nachoretro/internetsearch)
- [GitHub MCP Package](https://www.npmjs.com/package/@modelcontextprotocol/server-github)
- [Model Context Protocol Docs](https://modelcontextprotocol.io)
- [OpenCode MCP Configuration](https://opencode.ai/docs/mcp)

---

**Engineering Sign-off**: Lt. Commander Data  
**Stardate**: 2026-05-28T04:00:00Z  
**Fleet Status**: MCP systems operational, awaiting final authentication configuration
