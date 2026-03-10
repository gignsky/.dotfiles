_: {
  programs.opencode.settings.mcp = {
    git = {
      type = "local";
      command = [
        "/home/gig/.dotfiles/home/gig/common/core/opencode/scripts/git-mcp-wrapper.sh"
      ];
      enabled = true;
      timeout = 15000;
    };
  };
}
