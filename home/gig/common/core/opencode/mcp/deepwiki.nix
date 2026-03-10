_: {
  # DeepWiki for repository documentation and history research
  programs.opencode.settings.mcp = {
    deepwiki = {
      type = "remote";
      url = "https://mcp.deepwiki.com/mcp";
      enabled = true;
      timeout = 20000; # 20 second timeout for repo documentation searches
    };
  };
}
