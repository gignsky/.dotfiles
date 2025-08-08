#!/usr/bin/env nu

# Flake build script with logging
# Rewritten from bash to nushell for better safety and logging

def main [
    package?: string,   # Package to build (optional)
    --file: string,     # Path to flake file (alternative to package)
] {
    # Navigate to dotfiles directory
    let dotfiles_dir = $"($env.HOME)/.dotfiles"
    
    if not ($dotfiles_dir | path exists) {
        print $"(ansi red)Error: .dotfiles directory not found at ($dotfiles_dir)(ansi reset)"
        exit 1
    }
    
    cd $dotfiles_dir
    
    # Determine what to build
    let build_target = if ($file != null) {
        print $"Building flake at ($file)"
        $file
    } else if ($package != null) {
        print $"Building package: ($package)"
        $".#($package)"
    } else {
        print "Building default package"
        "."
    }
    
    # Create log file with timestamp
    let timestamp = (date now | format date "%Y-%m-%d_%H-%M-%S")
    let package_name = if ($package != null) { $package } else { "default" }
    let log_file = $"rebuild-logs/flake-build-($package_name)-($timestamp).log"
    
    # Ensure log directory exists
    mkdir rebuild-logs
    
    print $"Building: ($build_target)"
    
    # Run nix build with logging
    let build_result = (run-external "nix" "build" $build_target "--no-link" | complete)
    
    # Save output to log file
    let log_content = [
        $"# Flake Build Log: ($timestamp)",
        $"# Target: ($build_target)",
        $"# Command: nix build ($build_target) --no-link",
        $"# Status: (if $build_result.exit_code == 0 { 'SUCCESS' } else { 'FAILURE' })",
        "",
        "## STDOUT:",
        $build_result.stdout,
        "",
        "## STDERR:",  
        $build_result.stderr,
        "",
        "## Git Status at Build Time:",
        (git status --porcelain | str join "\n")
    ] | str join "\n"
    
    $log_content | save $log_file
    
    if $build_result.exit_code == 0 {
        print $"(ansi green)✅ Build successful: ($build_target)(ansi reset)"
        
        # Commit build log
        let commit_msg = $"flake-build: ($timestamp) - SUCCESS - ($package_name)"
        
        try {
            git add $log_file
            git commit -m $commit_msg
            print $"(ansi green)📝 Committed build log: ($commit_msg)(ansi reset)"
        } catch { |e|
            print $"(ansi yellow)⚠️ Failed to commit build log: ($e.msg)(ansi reset)"
        }
        
    } else {
        print $"(ansi red)❌ Build failed with exit code ($build_result.exit_code)(ansi reset)"
        print "Check the log file for details:"
        print $"  cat ($log_file)"
        
        # Show last few lines of error for immediate feedback
        print "\nLast few lines of error output:"
        print $build_result.stderr | lines | last 10 | str join "\n"
        
        # Commit failure log too
        let commit_msg = $"flake-build: ($timestamp) - FAILURE - ($package_name)"
        
        try {
            git add $log_file
            git commit -m $commit_msg
            print $"(ansi yellow)📝 Committed failure log: ($commit_msg)(ansi reset)"
        } catch { |e|
            print $"(ansi yellow)⚠️ Failed to commit failure log: ($e.msg)(ansi reset)"
        }
        
        exit $build_result.exit_code
    }
}