# MCP Tools Reference

**Purpose:** Comprehensive reference for all Model Context Protocol (MCP) tools available to OpenCode agents in the fleet.

**Last Updated:** 2026-02-02  
**Maintained By:** Fleet Engineering

---

## Overview

MCP tools extend agent capabilities by providing external integrations. All MCP tools are prefixed with their server name when invoked (e.g., `wikipedia_getPage`, not `wiki.page`).

**Configuration Location:** `~/.dotfiles/home/gig/common/core/opencode.nix`

---

## Active MCP Servers

### Wikipedia (`@shelm/wikipedia-mcp-server`)

**Type:** Local (npx-based)  
**Status:** ✅ Active  
**Timeout:** 10000ms  
**Purpose:** General knowledge and research queries

#### Available Tools

##### `wikipedia_onThisDay`
Get historical events that occurred on a specific date.

**Parameters:**
- `date` (string, required): ISO8601 date format (YYYY-MM-DD)

**Example:**
```javascript
wikipedia_onThisDay({ date: "2026-02-02" })
```

**Returns:** JSON object containing historical events (births, deaths, events, holidays, selected)

---

##### `wikipedia_findPage`
Search for Wikipedia pages matching a query.

**Parameters:**
- `query` (string, required): Search query string

**Example:**
```javascript
wikipedia_findPage({ query: "Sea of Tranquility" })
```

**Returns:** JSON object with search results including page titles and snippets

---

##### `wikipedia_getPage`
Get full content of a Wikipedia page by title.

**Parameters:**
- `title` (string, required): Exact Wikipedia page title

**Example:**
```javascript
wikipedia_getPage({ title: "Mare Tranquillitatis" })
```

**Returns:** JSON object containing:
- `title`: Page title
- `summary`: Page summary
- `content`: Full page content
- `url`: Full URL to the page

---

##### `wikipedia_getImagesForPage`
Get images from a Wikipedia page.

**Parameters:**
- `title` (string, required): Wikipedia page title
- `limit` (string|number, optional): Maximum number of images to retrieve (default: 50)

**Example:**
```javascript
wikipedia_getImagesForPage({ title: "Apollo 11", limit: 10 })
```

**Returns:** JSON array of image objects with URLs and metadata

**Note:** Filters for common image formats (svg, gif, jpg, jpeg, png, webp)

---

### DeepWiki (`https://mcp.deepwiki.com/sse`)

**Type:** Remote (SSE)  
**Status:** ✅ Active  
**Timeout:** 20000ms  
**Purpose:** Repository documentation and history research

#### Available Tools

**Note:** Tool details to be documented. DeepWiki provides access to up-to-date documentation for public repositories.

**Known Capabilities:**
- Repository documentation search
- Historical code analysis
- Documentation retrieval

**Action Required:** Document specific tool names and signatures

---

## Inactive/Commented MCP Servers

The following servers are configured but currently disabled in `opencode.nix`:

### ArXiv (Commented)
- **Package:** `uvx arxiv-mcp-server`
- **Purpose:** Academic paper research
- **Status:** ⏸️ Disabled

### Context7 (Commented)
- **URL:** `https://mcp.context7.com/mcp`
- **Purpose:** Documentation search
- **Status:** ⏸️ Disabled

### GitHub Grep (Commented)
- **URL:** `https://mcp.grep.app`
- **Purpose:** GitHub code search
- **Status:** ⏸️ Disabled

---

## Common Issues & Troubleshooting

### Issue: "function is not a function" Error

**Symptom:** Error like `wiki.search is not a function`

**Cause:** Incorrect function name without MCP server prefix

**Solution:** Always use the full MCP tool name with server prefix:
- ❌ Wrong: `wiki.search()`
- ✅ Correct: `wikipedia_findPage()`

### Issue: MCP Server Not Responding

**Diagnostic Steps:**
1. Check if `npx` is available: `which npx`
2. Test server directly: `npx -y @shelm/wikipedia-mcp-server`
3. Check OpenCode logs: `~/.local/share/opencode/log/`
4. Verify configuration: `cat ~/.config/opencode/config.json`

### Issue: Timeout Errors

**Solution:** Adjust timeout in `opencode.nix` for the specific MCP server:
```nix
mcp = {
  wikipedia = {
    timeout = 15000; # Increase from 10000
  };
};
```

---

## Adding New MCP Servers

When adding new MCP servers to the fleet:

1. **Update Configuration** in `~/.dotfiles/home/gig/common/core/opencode.nix`
2. **Document Tools** in this reference file
3. **Test Connectivity** before committing
4. **Update Agent Rules** to mention the new server
5. **Commit Changes** following fleet git standards

---

## Related Documentation

- **OpenCode Configuration:** `~/.dotfiles/home/gig/common/core/opencode.nix`
- **MCP Server Logs:** `~/.local/share/opencode/log/`
- **MCP Protocol Spec:** https://modelcontextprotocol.io/

---

**Computer Note:** This registry should be consulted when calling MCP tools to ensure correct function names and signatures. Always use the server prefix in tool names.
