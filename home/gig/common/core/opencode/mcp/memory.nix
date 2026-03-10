_: {
  packages.opencode.settings.mcp = {
    # Knowledge graph persistence for long-term memory across sessions
    memory = {
      type = "local";
      command = [
        "npx"
        "-y"
        "@modelcontextprotocol/server-memory"
      ];
      enabled = true;
      timeout = 10000; # 10 second timeout for memory operations
      env = {
        # Storage location for persistent knowledge graph
        MEMORY_FILE_PATH = "/home/gig/.local/share/annex-memory/memory.jsonl";
      };
    };
  };
}
