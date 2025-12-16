#!/usr/bin/env bash
# Order capture and agent dispatch system
# Allows quick thought capture with intelligent filing and agent task assignment

set -euo pipefail

# Detect the current git repository root to support worktrees
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "${HOME}/.dotfiles")
NOTES_DIR="$REPO_ROOT/operations/inbox"
TEMP_NOTE="/tmp/order-capture-$(date +%Y%m%d-%H%M%S).md"

# Function to capture user input in nvim
capture_thought() {
    echo "📝 Capturing your thought in nvim..."
    echo "# Quick Order/Thought Capture - $(date)" > "$TEMP_NOTE"
    echo "" >> "$TEMP_NOTE"
    echo "**Date:** $(date '+%Y-%m-%d %H:%M:%S')" >> "$TEMP_NOTE"
    echo "**Type:** [Order/Thought/Idea/Task]" >> "$TEMP_NOTE"
    echo "" >> "$TEMP_NOTE"
    echo "## Content" >> "$TEMP_NOTE"
    echo "" >> "$TEMP_NOTE"
    
    # Open in nvim for editing
    nvim + "$TEMP_NOTE"
    
    # Check if file has meaningful content beyond the template
    if [[ $(wc -l < "$TEMP_NOTE") -lt 10 ]]; then
        echo "❌ No content captured. Exiting."
        rm -f "$TEMP_NOTE"
        exit 1
    fi
    
    echo "✅ Thought captured successfully."
}

# Function to prompt for immediate exit
prompt_exit_choice() {
    echo ""
    echo "Choose your next action:"
    echo "1) Exit immediately (let Scotty file this automatically)"
    echo "2) Continue with interactive analysis"
    echo ""
    read -p "Your choice (1/2): " choice
    
    case "$choice" in
        1|"")
            return 0  # Exit immediately
            ;;
        2)
            return 1  # Continue with analysis
            ;;
        *)
            echo "Invalid choice. Defaulting to immediate exit."
            return 0
            ;;
    esac
}

# Function for interactive analysis (future implementation)
interactive_analysis() {
    echo "🔍 Interactive analysis mode not yet implemented."
    echo "📋 For now, proceeding with automatic filing..."
    return 0
}

# Function to dispatch to appropriate agent
dispatch_to_agent() {
    local note_file="$1"
    local note_content=$(cat "$note_file")
    
    # Detect mentioned agents (simple pattern matching)
    local mentioned_agent=""
    if echo "$note_content" | grep -qi "scotty"; then
        mentioned_agent="scotty"
    elif echo "$note_content" | grep -qi "cortana"; then
        mentioned_agent="cortana"
    else
        mentioned_agent="scotty"  # Default
    fi
    
    echo "🤖 Dispatching to agent: $mentioned_agent"
    
    # For now, just file in appropriate location
    # Future: Actually invoke the agent with the content
    
    local timestamp=$(date '+%Y-%m-%d')
    local filename="${timestamp}_order-capture-$(date '+%H%M%S').md"
    
    # Enhance the note with metadata
    {
        echo "# Order Capture - Auto-Filed"
        echo ""
        echo "**Created:** $(date '+%Y-%m-%d %H:%M:%S')"
        echo "**Assigned Agent:** $mentioned_agent"
        echo "**Source:** \`just order\` command"
        echo ""
        echo "---"
        echo ""
        cat "$note_file"
    } > "$NOTES_DIR/$filename"
    
    echo "📁 Filed as: operations/inbox/$filename"
    echo "🤖 Agent $mentioned_agent will process this when directed."
    
    # Commit the new note
    cd "$DOTFILES_DIR"
    git add "operations/inbox/$filename"
    git commit -m "ops: auto-file order capture via 'just order' command

Quick thought capture and agent dispatch: $mentioned_agent assigned.
Content filed in inbox for processing.

Created-By: order-capture-system"
    
    echo "✅ Note committed to repository."
}

main() {
    echo "🚀 Lord Gig's Order Capture System"
    echo "=================================="
    
    capture_thought
    
    if prompt_exit_choice; then
        echo "🏃 Proceeding with immediate filing..."
        dispatch_to_agent "$TEMP_NOTE"
    else
        echo "🔍 Starting interactive analysis..."
        interactive_analysis
        dispatch_to_agent "$TEMP_NOTE"
    fi
    
    # Cleanup
    rm -f "$TEMP_NOTE"
    
    echo ""
    echo "🎯 Order captured and filed successfully!"
    echo "📋 Use 'just inbox' to view pending items."
}

main "$@"
