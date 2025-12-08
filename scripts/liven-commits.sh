#!/bin/bash

# =============================================================================
# LIVEN-COMMITS COMMAND IMPLEMENTATION
# =============================================================================
# Manual commit enhancement command for Scotty agent
# Usage: /liven-commits [commit-range] [--dry-run] [--interactive]

# Source the commit enhancement library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/commit-enhance-lib.sh"

# Command line argument parsing
COMMIT_RANGE="HEAD~5..HEAD"
DRY_RUN=false
INTERACTIVE=false
REPO_DIR="$(pwd)"

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run|-n)
            DRY_RUN=true
            shift
            ;;
        --interactive|-i)
            INTERACTIVE=true
            shift
            ;;
        --help|-h)
            cat << EOF
🔧 SCOTTY'S COMMIT LIVENING PROTOCOL

Usage: /liven-commits [commit-range] [options]

Arguments:
  commit-range    Git commit range to process (default: HEAD~5..HEAD)
                  Examples: HEAD~10..HEAD, main..feature-branch, abc123..def456

Options:
  --dry-run, -n   Show what would be enhanced without making changes
  --interactive, -i  Interactively confirm each enhancement
  --help, -h      Show this help message

Examples:
  /liven-commits                    # Enhance last 5 commits
  /liven-commits HEAD~10..HEAD      # Enhance last 10 commits
  /liven-commits --dry-run          # Preview enhancements
  /liven-commits main..HEAD -i      # Interactive enhancement of branch

This command follows Lord Gig's Standards of Commitence and adds:
- Technical context (git state, generation info)
- Agent signatures with timestamps
- Conventional commit validation
- Enhanced descriptions with system information

Chief-Engineer: Scotty
EOF
            exit 0
            ;;
        --*)
            echo "Unknown option: $1" >&2
            echo "Use --help for usage information" >&2
            exit 1
            ;;
        *)
            COMMIT_RANGE="$1"
            shift
            ;;
    esac
done

# Validate we're in a git repository
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "❌ ERROR: Not in a git repository!" >&2
    exit 1
fi

# Set agent context for signatures
export SCOTTY_AGENT=true

echo "🔧 SCOTTY'S COMMIT LIVENING PROTOCOL ENGAGED"
echo "======================================================"
echo "Repository: $(basename "$(git rev-parse --show-toplevel)")"
echo "Branch: $(git branch --show-current)"
echo "Range: $COMMIT_RANGE"
echo "Mode: $([ "$DRY_RUN" = true ] && echo "DRY RUN" || echo "LIVE ENHANCEMENT")"
echo "Interactive: $([ "$INTERACTIVE" = true ] && echo "YES" || echo "NO")"
echo ""

# Get list of commits to process
commits=$(git rev-list --reverse "$COMMIT_RANGE" 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "❌ ERROR: Invalid commit range: $COMMIT_RANGE" >&2
    exit 1
fi

if [ -z "$commits" ]; then
    echo "ℹ️  No commits found in range: $COMMIT_RANGE"
    exit 0
fi

commit_count=$(echo "$commits" | wc -l)
echo "Found $commit_count commits to analyze..."
echo ""

enhanced_count=0
skipped_count=0
error_count=0

for commit in $commits; do
    commit_oneline=$(git log --oneline -n1 "$commit")
    echo "🔍 Analyzing: $commit_oneline"
    
    # Get original commit message
    original_message=$(git log --format=%B -n1 "$commit")
    
    # Check if already enhanced
    if echo "$original_message" | grep -qE "(Chief-Engineer|Captain|Auto-System):"; then
        echo "  ✓ Already enhanced, skipping"
        ((skipped_count++))
        echo ""
        continue
    fi
    
    # Validate and enhance the message
    enhanced_message=$(process_commit_message "$original_message" "liven-commits" "$REPO_DIR" true)
    if [ $? -ne 0 ]; then
        echo "  ✗ Validation failed:"
        echo "$enhanced_message" | sed 's/^/    /' >&2
        ((error_count++))
        echo ""
        continue
    fi
    
    # Show the enhancement
    echo "  📝 Enhanced message:"
    echo "$enhanced_message" | sed 's/^/    /'
    echo ""
    
    # Interactive confirmation
    if [ "$INTERACTIVE" = true ]; then
        echo -n "  Apply this enhancement? [Y/n/q]: "
        read -r response
        case "$response" in
            [nN]|[nN][oO])
                echo "  ⏭️  Skipped by user"
                ((skipped_count++))
                echo ""
                continue
                ;;
            [qQ]|[qQ][uU][iI][tT])
                echo "  🛑 User requested quit"
                break
                ;;
        esac
    fi
    
    # Apply enhancement (unless dry run)
    if [ "$DRY_RUN" = false ]; then
        # Use filter-branch to rewrite the commit message
        if git -c user.name="Chief Engineer Scotty" \
           -c user.email="scotty@starfleet.engineering" \
           commit-tree "$commit^{tree}" \
           -p "$(git rev-parse "$commit^" 2>/dev/null || echo "")" \
           -m "$enhanced_message" >/dev/null; then
            echo "  ✅ Enhanced successfully"
            ((enhanced_count++))
        else
            echo "  ✗ Failed to apply enhancement"
            ((error_count++))
        fi
    else
        echo "  🔄 Would enhance (dry run mode)"
        ((enhanced_count++))
    fi
    
    echo ""
done

echo "======================================================"
echo "🎯 LIVENING PROTOCOL COMPLETE"
echo ""
echo "📊 Summary:"
echo "  Enhanced: $enhanced_count"
echo "  Skipped:  $skipped_count" 
echo "  Errors:   $error_count"
echo "  Total:    $commit_count"
echo ""

if [ "$DRY_RUN" = false ] && [ $enhanced_count -gt 0 ]; then
    echo "⚠️  IMPORTANT: Commit history has been modified!"
    echo "   If this branch has been pushed, you may need to force-push:"
    echo "   git push --force-with-lease origin $(git branch --show-current)"
    echo ""
    echo "🔧 Engineering recommendation: Test builds before pushing"
fi

if [ $error_count -gt 0 ]; then
    echo "❌ Some commits failed enhancement. Check Lord Gig's Standards of Commitence."
    exit 1
fi

echo "⭐ All systems nominal, Captain!"
exit 0
