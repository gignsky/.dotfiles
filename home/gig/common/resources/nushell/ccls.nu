# Enhanced ccls function - System information display with multiple fetch tools
# Supports random selection, specific tool choice, and interactive mode

def ccls [
    target?: string      # Optional: specific fetch tool name or 'i'/'interactive' 
    --interactive(-i)    # Interactive mode for tool selection
    --random(-r) # random tool mode
] {
    # Available fetch tools in nixpkgs
    let fetch_tools = [
        "fastfetch"
        "neofetch" 
        "leaf"
        "honeyfetch"
        "microfetch"
        "macchina"
    ]
    
    # Clear the screen first
    clear
    
    # Determine which tool to use based on input
    let selected_tool = if ($interactive or $target == "i" or $target == "interactive" or $target == "--interactive") {
        # Interactive mode - let user choose with fzf-style selection
        echo "🔧 Choose yer fetch tool, Captain:"
        $fetch_tools | input list
    } else if ($target != null) {
        # Specific tool requested - validate it exists
        if ($target in $fetch_tools) {
            $target
        } else {
            print $"⚠️  Unknown fetch tool '($target)'. Available options:"
            $fetch_tools | each { |tool| print $"   • ($tool)" }
            print $"\n🔧 Fallin' back to fastfetch, Captain!"
            "fastfetch"
        }
    } else if ($random or $target == "r" or $target == "random" or target == "--random") {
        # Random mode - pick a random tool
        $fetch_tools | get (random int 0..($fetch_tools | length))
    } else {
        # fallback to default of fastfetch
        "fastfetch"
  }
    
    # Display what we're running
    print $"🚀 Runnin' ($selected_tool)..."
    print ""
    
    # Execute the selected fetch tool via nix run
    # This keeps packages on-demand (no bloat) - they're only fetched when called
    try {
        nix run $"nixpkgs#($selected_tool)"
    } catch {
        print $"❌ Engine trouble with ($selected_tool), Captain!"
        print "🔧 Falling back to fastfetch..."
        nix run nixpkgs#fastfetch
    }
}

# Helper function to show available tools
def "ccls list" [] {
    print "🔧 Available fetch tools:"
    [
        "fastfetch"
        "neofetch" 
        "leaf"
        "honeyfetch"
        "microfetch"
        "macchina"
    ] | each { |tool| print $"   • ($tool)" }
    print "\n📋 Usage examples:"
    print "   ccls              # Fastfetch (by-default)"
    print "   ccls fastfetch    # Specific tool"
    print "   ccls -i           # Interactive selection"
    print "   ccls -r           # Random selection"
    print "   ccls list         # Show this help"
}
