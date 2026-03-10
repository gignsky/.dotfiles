_: {
  packages.opencode.settings.mcp = {
    # Wikipedia access for research
    wikipedia = {
      type = "local";
      command = [
        "npx"
        "-y"
        "@shelm/wikipedia-mcp-server"
      ];
      enabled = true;
      timeout = 10000; # 10 second timeout for searches
    };
  };
}
