#!/usr/bin/env nu

# Quick Setup Script for GITHUB_TOKEN
# Run this to set up GitHub authentication for OpenCode MCP servers

print "🔧 GitHub Token Setup for OpenCode MCP Servers\n"

# Check if GITHUB_TOKEN is already set
if ($env.GITHUB_TOKEN? | is-not-empty) {
    print "✅ GITHUB_TOKEN is already set in your environment"
    print $"   Token: ($env.GITHUB_TOKEN | str substring 0..10)..."
    print ""
} else {
    print "⚠️  GITHUB_TOKEN is not set"
    print ""
}

print "📋 Setup Options:\n"
print "1. Quick Setup (Nushell config)"
print "   Add to ~/.config/nushell/env.nu:"
print "   $env.GITHUB_TOKEN = \"ghp_YOUR_TOKEN_HERE\""
print ""

print "2. GitHub CLI (if installed)"
print "   gh auth login"
print "   # Then add to env.nu:"
print "   $env.GITHUB_TOKEN = (gh auth token)"
print ""

print "3. Create GitHub Personal Access Token:"
print "   🌐 https://github.com/settings/tokens/new"
print "   Required scopes: repo, read:user, read:org"
print ""

print "🔍 To test if it works:"
print "   # In a new shell:"
print "   $env.GITHUB_TOKEN | str length  # Should show ~40"
print "   # Then restart OpenCode"
print ""

# Check if gh CLI is available
if (which gh | is-not-empty) {
    print "✅ GitHub CLI (gh) is installed"
    print "   Run: gh auth login"
    print ""
    
    try {
        let status = (gh auth status 2>&1 | complete)
        if ($status.exit_code == 0) {
            print "✅ GitHub CLI is authenticated"
            print "   Get token: gh auth token"
            print ""
        } else {
            print "⚠️  GitHub CLI not authenticated"
            print "   Run: gh auth login"
            print ""
        }
    } catch {
        print "ℹ️  Run 'gh auth status' to check authentication"
    }
} else {
    print "ℹ️  GitHub CLI (gh) is not installed"
    print "   You'll need to create a token manually at:"
    print "   🌐 https://github.com/settings/tokens"
    print ""
}

print "📝 After setting GITHUB_TOKEN:"
print "   1. Restart your shell (or source env.nu)"
print "   2. Verify: echo $env.GITHUB_TOKEN"
print "   3. Restart OpenCode"
print "   4. GitHub MCP tools will now work!"
print ""
