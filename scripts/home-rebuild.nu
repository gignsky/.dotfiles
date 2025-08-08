#!/usr/bin/env nu

# Home Manager rebuild script with logging
# Rewritten from bash to nushell for better safety and logging

def main [host?: string] {
    # Determine host name
    let target_host = if ($host != null) {
        $host
    } else {
        if (hostname) == "nixos" { "wsl" } else { hostname }
    }
    
    print $"Using host: gig@($target_host)"
    
    # Navigate to dotfiles directory
    let dotfiles_dir = $"($env.HOME)/.dotfiles"
    
    if not ($dotfiles_dir | path exists) {
        print $"(ansi red)Error: .dotfiles directory not found at ($dotfiles_dir)(ansi reset)"
        exit 1
    }
    
    cd $dotfiles_dir
    
    # Show git diff for .nix files
    print "Git diff for .nix files:"
    try {
        git diff -U0 "*.nix"
    } catch {
        print "No .nix file changes detected"
    }
    
    print "Home-Manager Rebuilding..."
    
    # Create log file with timestamp
    let timestamp = (date now | format date "%Y-%m-%d_%H-%M-%S")
    let log_file = $"rebuild-logs/home-manager-rebuild-($target_host)-($timestamp).log"
    
    # Ensure log directory exists
    mkdir rebuild-logs
    
    # Run home-manager rebuild with logging
    let rebuild_result = (run-external "home-manager" "switch" "--flake" $".#gig@($target_host)" | complete)
    
    # Save output to log file
    let log_content = [
        $"# Home Manager Rebuild Log: ($timestamp)",
        $"# User@Host: gig@($target_host)",
        $"# Command: home-manager switch --flake .#gig@($target_host)",
        $"# Status: (if $rebuild_result.exit_code == 0 { 'SUCCESS' } else { 'FAILURE' })",
        "",
        "## STDOUT:",
        $rebuild_result.stdout,
        "",
        "## STDERR:",  
        $rebuild_result.stderr,
        "",
        "## Git Status at Build Time:",
        (git status --porcelain | str join "\n")
    ] | str join "\n"
    
    $log_content | save $log_file
    
    if $rebuild_result.exit_code == 0 {
        print $"(ansi green)✅ Home Manager rebuild successful(ansi reset)"
        
        # Get generation info for commit message
        let gen_info = (run-external "home-manager" "generations" | complete)
        let current_gen = if $gen_info.exit_code == 0 {
            $gen_info.stdout | lines | get 0?
        } else {
            $"generation info unavailable"
        }
        
        # Commit changes with generation info
        let commit_msg = $"gig@($target_host): ($timestamp) -> ($current_gen)"
        
        try {
            git add .
            git commit --allow-empty -m $commit_msg
            print $"(ansi green)📝 Committed with message: ($commit_msg)(ansi reset)"
        } catch { |e|
            print $"(ansi yellow)⚠️ Failed to commit: ($e.msg)(ansi reset)"
        }
        
    } else {
        print $"(ansi red)❌ Home Manager rebuild failed with exit code ($rebuild_result.exit_code)(ansi reset)"
        print "Check the log file for details:"
        print $"  cat ($log_file)"
        
        # Show last few lines of error for immediate feedback
        print "\nLast few lines of error output:"
        print $rebuild_result.stderr | lines | last 10 | str join "\n"
        
        exit $rebuild_result.exit_code
    }
}