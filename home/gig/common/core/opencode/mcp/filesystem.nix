_: {
  programs.opencode.settings.mcp = {
    # Filesystem operations with permission-bounded directory access
    filesystem = {
      type = "local";
      command = [
        "npx"
        "-y"
        "@modelcontextprotocol/server-filesystem"
        "/home/gig/local_repos"
        "/home/gig/.dotfiles"
      ];
      enabled = true;
      timeout = 10000; # 10 second timeout for file operations
    };
  };
}
