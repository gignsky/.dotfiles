_: {
  programs.opencode.settings.mcp = {
    # Knowledge graph persistence for long-term memory across sessions
    # Note: Uses default storage location in npx cache directory
    # Custom location would require shell wrapper due to home-manager module limitations
    memory = {
      type = "local";
      command = [
        "npx"
        "-y"
        "@modelcontextprotocol/server-memory"
      ];
      enabled = true;
      timeout = 10000; # 10 second timeout for memory operations
    };
  };
}
