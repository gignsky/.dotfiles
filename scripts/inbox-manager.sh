#!/usr/bin/env bash
# Inbox management script for Captain's operational workflow

set -euo pipefail

# Detect the current git repository root to support worktrees
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "${HOME}/.dotfiles")
INBOX_DIR="${REPO_ROOT}/operations/inbox"
OUTBOX_DIR="${REPO_ROOT}/operations/outbox"

show_inbox_status() {
    echo "📥 Captain's Operational Inbox Status:"
    echo ""
    
    if [[ ! -d "$INBOX_DIR" ]]; then
        echo "  ❌ Inbox directory not found"
        return 1
    fi
    
    cd "$INBOX_DIR"
    local total=$(find . -name "*.md" ! -name "README.md" | wc -l)
    
    if [[ $total -eq 0 ]]; then
        echo "  ✅ Inbox empty - no items pending review"
        return 0
    fi
    
    echo "  📊 Total items: $total"
    echo ""
    echo "  📋 Items by priority:"
    
    local urgent=$(grep -l "URGENT" *.md 2>/dev/null | wc -l)
    local high=$(grep -l "HIGH" *.md 2>/dev/null | wc -l)
    local medium=$(grep -l "MEDIUM" *.md 2>/dev/null | wc -l)
    local low=$(grep -l "LOW" *.md 2>/dev/null | wc -l)
    
    [[ $urgent -gt 0 ]] && echo "    🔴 URGENT: $urgent"
    [[ $high -gt 0 ]] && echo "    🟡 HIGH: $high"
    [[ $medium -gt 0 ]] && echo "    🟠 MEDIUM: $medium"
    [[ $low -gt 0 ]] && echo "    🟢 LOW: $low"
    
    echo ""
    echo "  📄 Items:"
    for file in *.md; do
        [[ "$file" == "README.md" ]] && continue
        local priority=$(grep -o "\*\*PRIORITY:\*\* [A-Z]*" "$file" 2>/dev/null | sed 's/\*\*PRIORITY:\*\* //' || echo "UNSET")
        echo "    $file ($priority)"
    done
}

show_quick_status() {
    echo "📊 Quick Inbox Status:"
    
    if [[ ! -d "$INBOX_DIR" ]]; then
        echo "  ❌ Inbox not found"
        return 1
    fi
    
    cd "$INBOX_DIR"
    local total=$(find . -name "*.md" ! -name "README.md" | wc -l)
    
    if [[ $total -eq 0 ]]; then
        echo "  ✅ Empty inbox"
        return 0
    fi
    
    echo "  📊 $total items total"
    
    local urgent=$(grep -l "URGENT" *.md 2>/dev/null | wc -l)
    [[ $urgent -gt 0 ]] && echo "  🔴 $urgent URGENT items"
    
    local oldest=$(find . -name "*.md" ! -name "README.md" -printf '%T@ %p\n' 2>/dev/null | sort -n | head -1 | cut -d' ' -f2- | sed 's|^./||')
    [[ -n "$oldest" ]] && echo "  📅 Oldest: $oldest"
}

case "${1:-status}" in
    "status")
        show_inbox_status
        ;;
    "quick")
        show_quick_status
        ;;
    *)
        echo "Usage: inbox-manager [status|quick]"
        exit 1
        ;;
esac
