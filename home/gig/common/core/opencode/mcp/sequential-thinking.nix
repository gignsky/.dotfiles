_: {
  packages.opencode.settings.mcp = {
    # Sequential thinking framework for structured problem-solving
    sequential-thinking = {
      type = "local";
      command = [
        "npx"
        "-y"
        "@modelcontextprotocol/server-sequential-thinking"
      ];
      enabled = true;
      timeout = 15000; # 15 second timeout for reasoning chains
    };
  };
}
