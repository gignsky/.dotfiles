#!/usr/bin/env nu

# Flake check script with logging
# Rewritten from bash to nushell for better safety and logging

def main [] {
    # Navigate to dotfiles directory
    let dotfiles_dir = $"($env.HOME)/.dotfiles"
    
    if not ($dotfiles_dir | path exists) {
        print $"(ansi red)Error: .dotfiles directory not found at ($dotfiles_dir)(ansi reset)"
        exit 1
    }
    
    cd $dotfiles_dir
    
    print "Running flake check..."
    
    # Create log file with timestamp
    let timestamp = (date now | format date "%Y-%m-%d_%H-%M-%S")
    let log_file = $"rebuild-logs/flake-check-($timestamp).log"
    
    # Ensure log directory exists
    mkdir rebuild-logs
    
    # Run nix flake check with logging
    let check_result = (run-external "nix" "flake" "check" "--no-link" | complete)
    
    # Save output to log file
    let log_content = [
        $"# Flake Check Log: ($timestamp)",
        $"# Command: nix flake check --no-link",
        $"# Status: (if $check_result.exit_code == 0 { 'SUCCESS' } else { 'FAILURE' })",
        "",
        "## STDOUT:",
        $check_result.stdout,
        "",
        "## STDERR:",  
        $check_result.stderr,
        "",
        "## Git Status at Check Time:",
        (git status --porcelain | str join "\n")
    ] | str join "\n"
    
    $log_content | save $log_file
    
    if $check_result.exit_code == 0 {
        print $"(ansi green)✅ Flake check passed(ansi reset)"
        
        # Commit success log
        let commit_msg = $"flake-check: ($timestamp) - SUCCESS"
        
        try {
            git add $log_file
            git commit -m $commit_msg
            print $"(ansi green)📝 Committed check log: ($commit_msg)(ansi reset)"
        } catch { |e|
            print $"(ansi yellow)⚠️ Failed to commit check log: ($e.msg)(ansi reset)"
        }
        
    } else {
        print $"(ansi red)❌ Flake check failed with exit code ($check_result.exit_code)(ansi reset)"
        print "Check the log file for details:"
        print $"  cat ($log_file)"
        
        # Show error output for immediate feedback
        print "\nError output:"
        print $check_result.stderr
        
        # Commit failure log
        let commit_msg = $"flake-check: ($timestamp) - FAILURE"
        
        try {
            git add $log_file
            git commit -m $commit_msg
            print $"(ansi yellow)📝 Committed failure log: ($commit_msg)(ansi reset)"
        } catch { |e|
            print $"(ansi yellow)⚠️ Failed to commit failure log: ($e.msg)(ansi reset)"
        }
        
        exit $check_result.exit_code
    }
}