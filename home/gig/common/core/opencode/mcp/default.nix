{ configLib, ... }:
# let
#   configLib = import (flakeRoot + /lib) { inherit lib; };
# in
{
  imports = configLib.scanPaths ./.;
}

# {pkgs,...}: {
#       # MCP servers for extended functionality
#       programs.opencode.settings.mcp = {
#         #
#         # # ArXiv access for academic research
#         # arxiv = {
#         #   type = "local";
#         #   command = [
#         #     "uvx"
#         #     "arxiv-mcp-server"
#         #   ];
#         #   enabled = true;
#         #   timeout = 15000; # 15 second timeout for paper searches
#         # };
#         #
#         # # Context7 for documentation search
#         # context7 = {
#         #   type = "remote";
#         #   url = "https://mcp.context7.com/mcp";
#         #   # Uncomment and set if you have an API key for higher rate limits
#         #   # headers = {
#         #   #   "CONTEXT7_API_KEY" = "{env:CONTEXT7_API_KEY}";
#         #   # };
#         # };
#         #
#         # # GitHub code search via Grep.app
#         # gh_grep = {
#         #   type = "remote";
#         #   url = "https://mcp.grep.app";
#         #   enabled = true;
#         # };
#
#       };
# }
