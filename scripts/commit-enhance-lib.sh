#!/usr/bin/env bash
# Commit Message Enhancement Library
# Part of Chief Engineer Montgomery Scott's Engineering Excellence Initiative

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m' 
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m' # No Color

# Configuration
readonly ENHANCEMENT_CONFIG_FILE="$HOME/.dotfiles/.commit-enhancement-config"

# Load enhancement preferences
load_enhancement_config() {
    if [[ -f "$ENHANCEMENT_CONFIG_FILE" ]]; then
        source "$ENHANCEMENT_CONFIG_FILE"
    else
        export COMMIT_ENHANCEMENT_ENABLED="true"
        export SUGGEST_IMPROVEMENTS="true"
        export SHOW_EXAMPLES="true"
    fi
}

# Detect problematic patterns in commit messages
detect_problematic_patterns() {
    local message="$1"
    local issues=()
    
    # Convert to lowercase for case-insensitive matching
    local lower_message=$(echo "$message" | tr '[:upper:]' '[:lower:]')
    
    # Check for overused terms
    if [[ "$lower_message" =~ (^|[[:space:]])final([[:space:]]|$) ]]; then
        issues+=("OVERUSED: 'final' - consider: complete, conclude, establish, integrate")
    fi
    
    if [[ "$lower_message" =~ (^|[[:space:]])update([[:space:]]|$) ]] && ! [[ "$lower_message" =~ (dependency|package|version) ]]; then
        issues+=("GENERIC: 'update' - consider: enhance, modernize, expand, refactor")
    fi
    
    if [[ "$lower_message" =~ (^|[[:space:]])fix([[:space:]]|$) ]] && ! [[ "$lower_message" =~ fix: ]]; then
        issues+=("VAGUE: 'fix' - consider: resolve, repair, correct, address")
    fi
    
    if [[ "$lower_message" =~ (^|[[:space:]])change([[:space:]]|$) ]]; then
        issues+=("MEANINGLESS: 'change' - be specific about what changed")
    fi
    
    # Check for conventional commit format
    if ! [[ "$message" =~ ^(feat|fix|docs|style|refactor|test|chore|build|ci|perf|revert): ]]; then
        issues+=("FORMAT: Consider conventional commit format (feat:, fix:, docs:, etc.)")
    fi
    
    # Check for too-short descriptions
    local subject=$(echo "$message" | head -n1)
    if [[ ${#subject} -lt 20 ]]; then
        issues+=("LENGTH: Subject line seems brief - consider adding more context")
    fi
    
    printf '%s\n' "${issues[@]}"
}

# Generate enhancement suggestions
suggest_enhancements() {
    local message="$1"
    local suggestions=()
    
    local lower_message=$(echo "$message" | tr '[:upper:]' '[:lower:]')
    
    if [[ "$lower_message" =~ (add|new) ]]; then
        suggestions+=("SUGGESTION: If adding functionality, consider 'feat:' prefix")
    fi
    
    if [[ "$lower_message" =~ (bug|error|issue) ]]; then
        suggestions+=("SUGGESTION: If fixing bugs, consider 'fix:' prefix")
    fi
    
    if [[ "$lower_message" =~ (documentation|readme|comment) ]]; then
        suggestions+=("SUGGESTION: If updating docs, consider 'docs:' prefix")
    fi
    
    if [[ "$lower_message" =~ (performance|speed|optimize) ]]; then
        suggestions+=("SUGGESTION: If improving performance, consider 'perf:' prefix")
    fi
    
    printf '%s\n' "${suggestions[@]}"
}

# Display enhancement report
show_enhancement_report() {
    local message="$1"
    local issues=($(detect_problematic_patterns "$message"))
    local suggestions=($(suggest_enhancements "$message"))
    
    if [[ ${#issues[@]} -gt 0 ]] || [[ ${#suggestions[@]} -gt 0 ]]; then
        echo -e "${BOLD}${CYAN}════════════════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${BOLD}${CYAN}CHIEF ENGINEER'S COMMIT MESSAGE ANALYSIS${NC}"
        echo -e "${BOLD}${CYAN}════════════════════════════════════════════════════════════════════════════════${NC}"
        echo
        echo -e "${BOLD}Original message:${NC}"
        echo -e "${YELLOW}$message${NC}"
        echo
        
        if [[ ${#issues[@]} -gt 0 ]]; then
            echo -e "${BOLD}${RED}Issues Detected:${NC}"
            for issue in "${issues[@]}"; do
                echo -e "  ${RED}●${NC} $issue"
            done
            echo
        fi
        
        if [[ ${#suggestions[@]} -gt 0 ]]; then
            echo -e "${BOLD}${GREEN}Engineering Recommendations:${NC}"
            for suggestion in "${suggestions[@]}"; do
                echo -e "  ${GREEN}●${NC} $suggestion"
            done
            echo
        fi
        
        if [[ "$SHOW_EXAMPLES" == "true" ]]; then
            show_examples_for_message "$message"
        fi
        
        echo -e "${BOLD}${CYAN}════════════════════════════════════════════════════════════════════════════════${NC}"
        return 0
    else
        echo -e "${GREEN}✓ Commit message quality: EXCELLENT${NC}"
        return 1
    fi
}

# Show relevant examples
show_examples_for_message() {
    local message="$1"
    local lower_message=$(echo "$message" | tr '[:upper:]' '[:lower:]')
    
    echo -e "${BOLD}${BLUE}Example Enhancements:${NC}"
    
    if [[ "$lower_message" =~ final ]]; then
        echo -e "  ${BLUE}Instead of:${NC} 'final update to login system'"
        echo -e "  ${BLUE}Consider:${NC}   'feat: complete user authentication system implementation'"
        echo
    fi
    
    if [[ "$lower_message" =~ update ]] && ! [[ "$lower_message" =~ (dependency|package|version) ]]; then
        echo -e "  ${BLUE}Instead of:${NC} 'update configuration'"
        echo -e "  ${BLUE}Consider:${NC}   'config: modernize database connection settings'"
        echo
    fi
    
    if [[ "$lower_message" =~ fix ]] && ! [[ "$lower_message" =~ fix: ]]; then
        echo -e "  ${BLUE}Instead of:${NC} 'fix bug in parser'"
        echo -e "  ${BLUE}Consider:${NC}   'fix: resolve null pointer exception in JSON parser'"
        echo
    fi
}

# Interactive enhancement mode
interactive_enhancement() {
    local original_message="$1"
    
    show_enhancement_report "$original_message"
    local has_issues=$?
    
    if [[ $has_issues -eq 0 ]]; then
        echo
        echo -e "${BOLD}Would you like to revise your commit message? ${NC}${CYAN}[y/N]${NC}"
        read -r response
        
        if [[ "$response" =~ ^[Yy]$ ]]; then
            echo -e "${BOLD}Enter improved commit message:${NC}"
            read -r improved_message
            
            if [[ -n "$improved_message" ]]; then
                echo
                echo -e "${GREEN}✓ Enhanced message:${NC}"
                echo -e "${BOLD}$improved_message${NC}"
                echo "$improved_message"
                return 0
            fi
        fi
    fi
    
    echo "$original_message"
    return 1
}

# Analyze recent commits
analyze_recent_commits() {
    local count=${1:-10}
    
    echo -e "${BOLD}${CYAN}════════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${CYAN}COMMIT MESSAGE QUALITY ANALYSIS - LAST $count COMMITS${NC}"
    echo -e "${BOLD}${CYAN}════════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    local total_issues=0
    local total_commits=0
    
    while IFS= read -r commit_line; do
        local hash=$(echo "$commit_line" | cut -d' ' -f1)
        local message=$(echo "$commit_line" | cut -d' ' -f2-)
        
        echo -e "${BOLD}Commit ${hash}:${NC} $message"
        
        local issues=($(detect_problematic_patterns "$message"))
        if [[ ${#issues[@]} -gt 0 ]]; then
            for issue in "${issues[@]}"; do
                echo -e "  ${RED}●${NC} $issue"
            done
            ((total_issues += ${#issues[@]}))
        else
            echo -e "  ${GREEN}✓ No issues detected${NC}"
        fi
        
        ((total_commits++))
        echo
    done < <(git log --oneline -n "$count")
    
    local quality_score=$((100 - (total_issues * 100 / total_commits)))
    echo -e "${BOLD}${CYAN}════════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}Quality Score: ${quality_score}% ${NC}(${total_issues} issues across ${total_commits} commits)"
    
    if [[ $quality_score -ge 80 ]]; then
        echo -e "${GREEN}✓ Engineering assessment: EXCELLENT commit message quality!${NC}"
    elif [[ $quality_score -ge 60 ]]; then
        echo -e "${YELLOW}⚠ Engineering assessment: GOOD quality, room for improvement${NC}"
    else
        echo -e "${RED}⚠ Engineering assessment: Significant improvement needed${NC}"
    fi
    
    echo -e "${BOLD}${CYAN}════════════════════════════════════════════════════════════════════════════════${NC}"
}

# Main command interface
main() {
    load_enhancement_config
    
    case "${1:-help}" in
        "analyze"|"check")
            if [[ -n "$2" ]]; then
                show_enhancement_report "$2"
            else
                echo "Usage: $0 analyze 'commit message'"
            fi
            ;;
        "interactive"|"improve")
            if [[ -n "$2" ]]; then
                interactive_enhancement "$2"
            else
                echo "Usage: $0 interactive 'commit message'"
            fi
            ;;
        "history"|"batch")
            analyze_recent_commits "${2:-10}"
            ;;
        "help"|*)
            cat << EOF
${BOLD}Chief Engineer's Commit Message Enhancement System${NC}

${BOLD}USAGE:${NC}
  $0 analyze 'commit message'     - Analyze a commit message for issues
  $0 interactive 'message'        - Interactive enhancement mode
  $0 history [count]              - Analyze recent commits (default: 10)  
  $0 help                         - Show this help message

${BOLD}EXAMPLES:${NC}
  $0 analyze 'final fix for login'
  $0 interactive 'update user system'
  $0 history 20
  
${BOLD}Integration with git:${NC}
  git commit -m "\$(./scripts/commit-enhance-lib.sh interactive 'my message')"
  
${GREEN}Engineering excellence through precise communication!${NC}
EOF
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
