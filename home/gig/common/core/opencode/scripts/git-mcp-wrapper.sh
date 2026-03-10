#!/usr/bin/env bash
# Git MCP Server Wrapper Script
# This script sets required environment variables before launching the Git MCP server
# Configuration is dynamically read from git global config

# Git email comes from git config (matches your commits)
# Git username - you may want to set: git config --global user.githubUsername "gignsky"
GIT_GITHUB_USER=$(git config --global user.githubUsername 2>/dev/null || echo "gignsky")

export MCP_TRANSPORT_TYPE="stdio"
export MCP_LOG_LEVEL="info"
export GIT_BASE_DIR="/home/gig/local_repos"
export GIT_USERNAME="$GIT_GITHUB_USER"
export GIT_EMAIL="$(git config --global user.email)"
export GIT_SIGN_COMMITS="false"

exec npx -y @cyanheads/git-mcp-server@latest "$@"
